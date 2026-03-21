/**
 * bclibc_ffi.cpp
 *
 * Thin C++ wrapper that implements the bclibc_ffi.h C API.
 * Mirrors the structure of the WASM bindings (wasm/bindings.cpp):
 *   - PCHIP curve building from a flat drag table
 *   - Engine initialisation from BCShotProps
 *   - Exception → error-code conversion
 */

#include "bclibc_ffi.h"

#include <cmath>
#include <cstring>
#include <cstdlib>
#include <stdexcept>
#include <vector>

#include "bclibc/base_types.hpp"
#include "bclibc/traj_data.hpp"
#include "bclibc/engine.hpp"
#include "bclibc/exceptions.hpp"
#include "bclibc/rk4.hpp"
#include "bclibc/euler.hpp"

using namespace bclibc;

// ============================================================================
// Internal constants (same as WASM bindings)
// ============================================================================

static constexpr double APEX_IS_MAX_RANGE_RADIANS = 0.0003;
static constexpr double ALLOWED_ZERO_ERROR_FEET   = 1e-2;

// ============================================================================
// PCHIP curve builder (ported 1-to-1 from wasm/bindings.cpp curveFromVal)
// ============================================================================

static BCLIBC_Curve buildCurve(const BCDragPoint* dt, int n) {
    if (n < 2)
        throw std::invalid_argument("Drag table requires at least 2 points");

    int nm1 = n - 1;
    std::vector<double> x(n), y(n);
    for (int i = 0; i < n; ++i) { x[i] = dt[i].Mach; y[i] = dt[i].CD; }

    std::vector<double> h(nm1), d(nm1), m(n);
    for (int i = 0; i < nm1; ++i) {
        h[i] = x[i + 1] - x[i];
        d[i] = (y[i + 1] - y[i]) / h[i];
    }

    if (n == 2) {
        m[0] = m[1] = d[0];
    } else {
        // Interior slopes – Fritsch–Carlson
        for (int i = 1; i < n - 1; ++i) {
            if (d[i-1] == 0.0 || d[i] == 0.0 || d[i-1] * d[i] < 0.0) {
                m[i] = 0.0;
            } else {
                double w1 = 2.0 * h[i]   + h[i-1];
                double w2 =       h[i]   + 2.0 * h[i-1];
                m[i] = (w1 + w2) / (w1 / d[i-1] + w2 / d[i]);
            }
        }
        // Left endpoint
        double m0 = ((2.0*h[0] + h[1])*d[0] - h[0]*d[1]) / (h[0] + h[1]);
        if (m0 * d[0] <= 0.0) m0 = 0.0;
        else if (d[0]*d[1] < 0.0 && std::fabs(m0) > 3.0*std::fabs(d[0])) m0 = 3.0*d[0];
        m[0] = m0;
        // Right endpoint
        double mn = ((2.0*h[n-2] + h[n-3])*d[n-2] - h[n-2]*d[n-3]) / (h[n-2] + h[n-3]);
        if (mn * d[n-2] <= 0.0) mn = 0.0;
        else if (d[n-2]*d[n-3] < 0.0 && std::fabs(mn) > 3.0*std::fabs(d[n-2])) mn = 3.0*d[n-2];
        m[n-1] = mn;
    }

    BCLIBC_Curve curve(nm1);
    for (int i = 0; i < nm1; ++i) {
        double H    = h[i];
        double yi   = y[i];
        double mi   = m[i];
        double mip1 = m[i + 1];
        double A    = (y[i+1] - yi - mi*H) / (H*H);
        double B    = (mip1 - mi) / H;
        curve[i].a  = (B - 2.0*A) / H;
        curve[i].b  = 3.0*A - B;
        curve[i].c  = mi;
        curve[i].d  = yi;
    }
    return curve;
}

static BCLIBC_MachList buildMachList(const BCDragPoint* dt, int n) {
    BCLIBC_MachList list;
    list.reserve(static_cast<size_t>(n));
    for (int i = 0; i < n; ++i) list.push_back(dt[i].Mach);
    return list;
}

// ============================================================================
// Error helpers
// ============================================================================

static void clearError(BCFFIError* e) {
    if (!e) return;
    e->code    = BCFFI_OK;
    e->message[0] = '\0';
    e->f64_0   = e->f64_1 = e->f64_2 = 0.0;
    e->i32_0   = 0;
}

static void setError(BCFFIError* e, BCFFIStatus code, const char* msg) {
    if (!e) return;
    e->code = static_cast<int32_t>(code);
    std::strncpy(e->message, msg, sizeof(e->message) - 1);
    e->message[sizeof(e->message) - 1] = '\0';
}

// ============================================================================
// Engine initialisation (mirrors WASM initEngine + shotPropsFromVal)
// ============================================================================

static double calcStep(BCIntegrationMethod m, double multiplier) {
    return (m == BC_INTEGRATION_RK4 ? 0.0025 : 0.5) * multiplier;
}

static BCLIBC_IntegrateCallable selectIntegrateFunc(BCIntegrationMethod m) {
    return (m == BC_INTEGRATION_RK4) ? BCLIBC_IntegrateCallable(BCLIBC_integrateRK4)
                                     : BCLIBC_IntegrateCallable(BCLIBC_integrateEULER);
}

static void initEngine(BCLIBC_BaseEngine& eng, const BCShotProps* p) {
    BCLIBC_Config config(
        p->config.cStepMultiplier,
        p->config.cZeroFindingAccuracy,
        p->config.cMinimumVelocity,
        p->config.cMaximumDrop,
        p->config.cMaxIterations,
        p->config.cGravityConstant,
        p->config.cMinimumAltitude);

    BCLIBC_Atmosphere atmo(
        p->atmo.t0, p->atmo.a0, p->atmo.p0,
        p->atmo.mach, p->atmo.density_ratio, p->atmo.cLowestTempC);

    BCLIBC_Coriolis coriolis(
        p->coriolis.sin_lat, p->coriolis.cos_lat,
        p->coriolis.sin_az,  p->coriolis.cos_az,
        p->coriolis.range_east,  p->coriolis.range_north,
        p->coriolis.cross_east,  p->coriolis.cross_north,
        p->coriolis.flat_fire_only,
        p->coriolis.muzzle_velocity_fps);

    BCLIBC_WindSock wind_sock;
    for (int i = 0; i < p->wind_count; ++i) {
        wind_sock.push(BCLIBC_Wind(
            p->winds[i].velocity_fps,
            p->winds[i].direction_from_rad,
            p->winds[i].until_distance_ft,
            p->winds[i].max_distance_ft));
    }
    wind_sock.update_cache();

    eng.shot = BCLIBC_ShotProps(
        p->bc,
        p->look_angle_rad,
        p->twist_inch,
        p->length_inch,
        p->diameter_inch,
        p->weight_grain,
        p->barrel_elevation_rad,
        p->barrel_azimuth_rad,
        p->sight_height_ft,
        std::cos(p->cant_angle_rad),
        std::sin(p->cant_angle_rad),
        p->alt0_ft,
        calcStep(p->method, p->config.cStepMultiplier),
        p->muzzle_velocity_fps,
        0.0, // stability_coefficient (computed lazily)
        buildCurve(p->drag_table, p->drag_table_count),
        buildMachList(p->drag_table, p->drag_table_count),
        atmo,
        coriolis,
        wind_sock,
        BCLIBC_TRAJ_FLAG_NONE);

    eng.integrate_func  = selectIntegrateFunc(p->method);
    eng.config          = config;
    eng.gravity_vector  = BCLIBC_V3dT(0.0, config.cGravityConstant, 0.0);
}

// ============================================================================
// Output conversions
// ============================================================================

static void toC(const BCLIBC_TrajectoryData& s, BCTrajectoryData& d) {
    d.time              = s.time;
    d.distance_ft       = s.distance_ft;
    d.velocity_fps      = s.velocity_fps;
    d.mach              = s.mach;
    d.height_ft         = s.height_ft;
    d.slant_height_ft   = s.slant_height_ft;
    d.drop_angle_rad    = s.drop_angle_rad;
    d.windage_ft        = s.windage_ft;
    d.windage_angle_rad = s.windage_angle_rad;
    d.slant_distance_ft = s.slant_distance_ft;
    d.angle_rad         = s.angle_rad;
    d.density_ratio     = s.density_ratio;
    d.drag              = s.drag;
    d.energy_ft_lb      = s.energy_ft_lb;
    d.ogw_lb            = s.ogw_lb;
    d.flag              = static_cast<int32_t>(s.flag);
}

static void toC(const BCLIBC_BaseTrajData& s, BCBaseTrajData& d) {
    d.time = s.time;
    d.px   = s.px; d.py = s.py; d.pz = s.pz;
    d.vx   = s.vx; d.vy = s.vy; d.vz = s.vz;
    d.mach = s.mach;
}

// ============================================================================
// Exception catch blocks (macro mirrors WASM wrapExceptions)
// ============================================================================

#define BCFFI_CATCH(err_ptr)                                                      \
    catch (const BCLIBC_OutOfRangeError& e) {                                     \
        setError(err_ptr, BCFFI_ERR_OUT_OF_RANGE, e.what());                      \
        if (err_ptr) {                                                             \
            (err_ptr)->f64_0 = e.requested_distance_ft;                           \
            (err_ptr)->f64_1 = e.max_range_ft;                                    \
            (err_ptr)->f64_2 = e.look_angle_rad;                                  \
        }                                                                          \
        return BCFFI_ERR_OUT_OF_RANGE;                                            \
    }                                                                              \
    catch (const BCLIBC_ZeroFindingError& e) {                                    \
        setError(err_ptr, BCFFI_ERR_ZERO_FINDING, e.what());                      \
        if (err_ptr) {                                                             \
            (err_ptr)->f64_0 = e.zero_finding_error;                              \
            (err_ptr)->f64_1 = e.last_barrel_elevation_rad;                       \
            (err_ptr)->i32_0 = e.iterations_count;                                \
        }                                                                          \
        return BCFFI_ERR_ZERO_FINDING;                                            \
    }                                                                              \
    catch (const BCLIBC_InterceptionError& e) {                                   \
        setError(err_ptr, BCFFI_ERR_INTERCEPTION, e.what());                      \
        return BCFFI_ERR_INTERCEPTION;                                            \
    }                                                                              \
    catch (const BCLIBC_SolverRuntimeError& e) {                                  \
        setError(err_ptr, BCFFI_ERR_SOLVER_RUNTIME, e.what());                    \
        return BCFFI_ERR_SOLVER_RUNTIME;                                          \
    }                                                                              \
    catch (const std::exception& e) {                                             \
        setError(err_ptr, BCFFI_ERR_GENERIC, e.what());                           \
        return BCFFI_ERR_GENERIC;                                                 \
    }

// ============================================================================
// Public C API
// ============================================================================

extern "C" {

int32_t bcffi_find_apex(
    const BCShotProps* props,
    BCTrajectoryData*  out,
    BCFFIError*        err)
{
    clearError(err);
    try {
        BCLIBC_BaseEngine eng;
        initEngine(eng, props);
        BCLIBC_BaseTrajData apex;
        eng.find_apex(apex);
        BCLIBC_TrajectoryData td(eng.shot, apex, BCLIBC_TRAJ_FLAG_APEX);
        toC(td, *out);
        return BCFFI_OK;
    }
    BCFFI_CATCH(err)
}

int32_t bcffi_find_max_range(
    const BCShotProps* props,
    double             low_angle_deg,
    double             high_angle_deg,
    BCMaxRangeResult*  out,
    BCFFIError*        err)
{
    clearError(err);
    try {
        BCLIBC_BaseEngine eng;
        initEngine(eng, props);
        BCLIBC_MaxRangeResult r = eng.find_max_range(
            low_angle_deg, high_angle_deg, APEX_IS_MAX_RANGE_RADIANS);
        out->max_range_ft    = r.max_range_ft;
        out->angle_at_max_rad = r.angle_at_max_rad;
        return BCFFI_OK;
    }
    BCFFI_CATCH(err)
}

int32_t bcffi_find_zero_angle(
    const BCShotProps* props,
    double             distance_ft,
    double*            out_angle_rad,
    BCFFIError*        err)
{
    clearError(err);
    try {
        BCLIBC_BaseEngine eng;
        initEngine(eng, props);
        *out_angle_rad = eng.zero_angle_with_fallback(
            distance_ft, APEX_IS_MAX_RANGE_RADIANS, ALLOWED_ZERO_ERROR_FEET);
        return BCFFI_OK;
    }
    BCFFI_CATCH(err)
}

int32_t bcffi_integrate(
    const BCShotProps*         props,
    const BCTrajectoryRequest* request,
    BCTrajectoryData**         out_records,
    int32_t*                   out_count,
    int32_t*                   out_reason,
    BCFFIError*                err)
{
    clearError(err);
    try {
        BCLIBC_BaseEngine eng;
        initEngine(eng, props);

        std::vector<BCLIBC_TrajectoryData> records;
        BCLIBC_TerminationReason reason;

        eng.integrate_filtered(
            request->range_limit_ft,
            request->range_step_ft,
            request->time_step,
            static_cast<BCLIBC_TrajFlag>(request->filter_flags),
            records,
            reason,
            nullptr);

        auto count = static_cast<int32_t>(records.size());
        BCTrajectoryData* arr = nullptr;
        if (count > 0) {
            arr = static_cast<BCTrajectoryData*>(
                std::malloc(sizeof(BCTrajectoryData) * static_cast<size_t>(count)));
            if (!arr) {
                setError(err, BCFFI_ERR_GENERIC, "Out of memory allocating trajectory");
                return BCFFI_ERR_GENERIC;
            }
            for (int32_t i = 0; i < count; ++i) toC(records[i], arr[i]);
        }

        *out_records = arr;
        *out_count   = count;
        *out_reason  = static_cast<int32_t>(reason);
        return BCFFI_OK;
    }
    BCFFI_CATCH(err)
}

void bcffi_free_trajectory(BCTrajectoryData* records) {
    std::free(records);
}

int32_t bcffi_integrate_at(
    const BCShotProps* props,
    int32_t            key,
    double             target_value,
    BCInterception*    out,
    BCFFIError*        err)
{
    clearError(err);
    try {
        BCLIBC_BaseEngine eng;
        initEngine(eng, props);

        BCLIBC_BaseTrajData   raw;
        BCLIBC_TrajectoryData full;
        eng.integrate_at(
            static_cast<BCLIBC_BaseTrajData_InterpKey>(key),
            target_value, raw, full);

        toC(raw,  out->raw_data);
        toC(full, out->full_data);
        return BCFFI_OK;
    }
    BCFFI_CATCH(err)
}

double bcffi_get_correction(double distance_ft, double offset_ft) {
    return BCLIBC_getCorrection(distance_ft, offset_ft);
}

double bcffi_calculate_energy(double bullet_weight_grain, double velocity_fps) {
    return BCLIBC_calculateEnergy(bullet_weight_grain, velocity_fps);
}

double bcffi_calculate_ogw(double bullet_weight_grain, double velocity_fps) {
    return BCLIBC_calculateOgw(bullet_weight_grain, velocity_fps);
}

} // extern "C"
