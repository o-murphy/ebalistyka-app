/**
 * bclibc_ffi.h
 *
 * Thin C interface over the bclibc ballistics engine.
 * Designed to be consumed by Dart FFI via ffigen.
 *
 * Mirrors the WASM bindings API surface (findApex, findMaxRange,
 * findZeroAngle, integrate, integrateAt) with flat C structs.
 */

#ifndef BCLIBC_FFI_H
#define BCLIBC_FFI_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Error codes
// ============================================================================

typedef enum BCFFIStatus {
    BCFFI_OK                  = 0,
    BCFFI_ERR_SOLVER_RUNTIME  = 1,
    BCFFI_ERR_OUT_OF_RANGE    = 2,
    BCFFI_ERR_ZERO_FINDING    = 3,
    BCFFI_ERR_INTERCEPTION    = 4,
    BCFFI_ERR_GENERIC         = 5,
} BCFFIStatus;

/** Error output struct – filled by every function on failure. */
typedef struct BCFFIError {
    int32_t code;         /**< BCFFIStatus */
    char    message[512]; /**< Null-terminated error message */
    /* Extra fields for typed errors */
    double  f64_0;   /**< OutOfRange: requested_distance_ft / ZeroFinding: zero_finding_error */
    double  f64_1;   /**< OutOfRange: max_range_ft          / ZeroFinding: last_barrel_elevation_rad */
    double  f64_2;   /**< OutOfRange: look_angle_rad */
    int32_t i32_0;   /**< ZeroFinding: iterations_count */
} BCFFIError;

// ============================================================================
// Enums
// ============================================================================

typedef enum BCTrajFlag {
    BC_TRAJ_FLAG_NONE      = 0,
    BC_TRAJ_FLAG_ZERO_UP   = 1,
    BC_TRAJ_FLAG_ZERO_DOWN = 2,
    BC_TRAJ_FLAG_ZERO      = 3,
    BC_TRAJ_FLAG_MACH      = 4,
    BC_TRAJ_FLAG_RANGE     = 8,
    BC_TRAJ_FLAG_APEX      = 16,
    BC_TRAJ_FLAG_ALL       = 31,
    BC_TRAJ_FLAG_MRT       = 32,
} BCTrajFlag;

typedef enum BCTerminationReason {
    BC_TERM_NO_TERMINATE              = 0,
    BC_TERM_TARGET_RANGE_REACHED      = 1,
    BC_TERM_MINIMUM_VELOCITY_REACHED  = 2,
    BC_TERM_MAXIMUM_DROP_REACHED      = 3,
    BC_TERM_MINIMUM_ALTITUDE_REACHED  = 4,
    BC_TERM_HANDLER_REQUESTED_STOP    = 5,
} BCTerminationReason;

/** Interpolation key for BCLIBC_BaseTrajData fields. */
typedef enum BCBaseTrajInterpKey {
    BC_INTERP_KEY_TIME  = 0,
    BC_INTERP_KEY_MACH  = 1,
    BC_INTERP_KEY_POS_X = 2,
    BC_INTERP_KEY_POS_Y = 3,
    BC_INTERP_KEY_POS_Z = 4,
    BC_INTERP_KEY_VEL_X = 5,
    BC_INTERP_KEY_VEL_Y = 6,
    BC_INTERP_KEY_VEL_Z = 7,
} BCBaseTrajInterpKey;

typedef enum BCIntegrationMethod {
    BC_INTEGRATION_RK4   = 0,
    BC_INTEGRATION_EULER = 1,
} BCIntegrationMethod;

// ============================================================================
// Input structs
// ============================================================================

typedef struct BCConfig {
    double  cStepMultiplier;
    double  cZeroFindingAccuracy;
    double  cMinimumVelocity;
    double  cMaximumDrop;
    int32_t cMaxIterations;
    double  cGravityConstant;
    double  cMinimumAltitude;
} BCConfig;

typedef struct BCAtmosphere {
    double t0;            /**< Temperature at base altitude (°F) */
    double a0;            /**< Base altitude (ft) */
    double p0;            /**< Pressure at base altitude (hPa) */
    double mach;          /**< Speed of sound (fps) */
    double density_ratio; /**< Air density / standard density */
    double cLowestTempC;  /**< Lowest allowed temperature (°C) */
} BCAtmosphere;

typedef struct BCCoriolis {
    double  sin_lat;
    double  cos_lat;
    double  sin_az;
    double  cos_az;
    double  range_east;
    double  range_north;
    double  cross_east;
    double  cross_north;
    int32_t flat_fire_only;       /**< Non-zero = flat-fire approximation */
    double  muzzle_velocity_fps;
} BCCoriolis;

typedef struct BCWind {
    double velocity_fps;
    double direction_from_rad;
    double until_distance_ft;
    double max_distance_ft; /**< Sentinel for last segment (use BCLIBC_cMaxWindDistanceFeet) */
} BCWind;

typedef struct BCDragPoint {
    double Mach;
    double CD;
} BCDragPoint;

/** Flat shot properties passed to every engine function. */
typedef struct BCShotProps {
    double bc;
    double look_angle_rad;
    double twist_inch;
    double length_inch;
    double diameter_inch;
    double weight_grain;
    double barrel_elevation_rad;
    double barrel_azimuth_rad;
    double sight_height_ft;
    double cant_angle_rad;
    double alt0_ft;
    double muzzle_velocity_fps;

    BCAtmosphere atmo;
    BCCoriolis   coriolis;
    BCConfig     config;

    BCIntegrationMethod method;

    /** Drag table – pointer must remain valid for the duration of the call. */
    const BCDragPoint* drag_table;
    int32_t            drag_table_count;

    /** Wind list – pointer must remain valid for the duration of the call. */
    const BCWind* winds;
    int32_t       wind_count;
} BCShotProps;

typedef struct BCTrajectoryRequest {
    double  range_limit_ft;
    double  range_step_ft;
    double  time_step;
    int32_t filter_flags; /**< BCTrajFlag bitmask */
} BCTrajectoryRequest;

// ============================================================================
// Output structs
// ============================================================================

typedef struct BCBaseTrajData {
    double time;
    double px;   /**< Position x (downrange, ft) */
    double py;   /**< Position y (height, ft) */
    double pz;   /**< Position z (windage, ft) */
    double vx;   /**< Velocity x (fps) */
    double vy;   /**< Velocity y (fps) */
    double vz;   /**< Velocity z (fps) */
    double mach;
} BCBaseTrajData;

typedef struct BCTrajectoryData {
    double  time;
    double  distance_ft;
    double  velocity_fps;
    double  mach;
    double  height_ft;
    double  slant_height_ft;
    double  drop_angle_rad;
    double  windage_ft;
    double  windage_angle_rad;
    double  slant_distance_ft;
    double  angle_rad;
    double  density_ratio;
    double  drag;
    double  energy_ft_lb;
    double  ogw_lb;
    int32_t flag; /**< BCTrajFlag */
} BCTrajectoryData;

typedef struct BCMaxRangeResult {
    double max_range_ft;
    double angle_at_max_rad;
} BCMaxRangeResult;

typedef struct BCInterception {
    BCBaseTrajData   raw_data;
    BCTrajectoryData full_data;
} BCInterception;

// ============================================================================
// Core functions
// ============================================================================

/**
 * Find the apex (highest point) of the trajectory.
 * @return BCFFI_OK on success, error code otherwise (fills *err).
 */
int32_t bcffi_find_apex(
    const BCShotProps* props,
    BCTrajectoryData*  out,
    BCFFIError*        err);

/**
 * Find the maximum range and corresponding angle.
 * @param low_angle_deg   Lower search bound (degrees).
 * @param high_angle_deg  Upper search bound (degrees).
 */
int32_t bcffi_find_max_range(
    const BCShotProps* props,
    double             low_angle_deg,
    double             high_angle_deg,
    BCMaxRangeResult*  out,
    BCFFIError*        err);

/**
 * Find the barrel elevation angle to zero at the given distance.
 * @param distance_ft     Slant distance to target (ft).
 * @param out_angle_rad   Output: barrel elevation (radians).
 */
int32_t bcffi_find_zero_angle(
    const BCShotProps* props,
    double             distance_ft,
    double*            out_angle_rad,
    BCFFIError*        err);

/**
 * Integrate trajectory and return filtered records.
 *
 * On success *out_records points to a heap-allocated BCTrajectoryData array
 * of length *out_count.  Call bcffi_free_trajectory() to release it.
 */
int32_t bcffi_integrate(
    const BCShotProps*        props,
    const BCTrajectoryRequest* request,
    BCTrajectoryData**        out_records,
    int32_t*                  out_count,
    int32_t*                  out_reason,  /**< BCTerminationReason */
    BCFFIError*               err);

/** Free a trajectory array allocated by bcffi_integrate(). */
void bcffi_free_trajectory(BCTrajectoryData* records);

/**
 * Integrate and interpolate the single point where a key field reaches
 * the target value.
 * @param key          BCBaseTrajInterpKey
 * @param target_value Value the key field must reach.
 */
int32_t bcffi_integrate_at(
    const BCShotProps*  props,
    int32_t             key,
    double              target_value,
    BCInterception*     out,
    BCFFIError*         err);

// ============================================================================
// Utility functions
// ============================================================================

/** Angular correction (radians) to hit target at distance with given offset. */
double bcffi_get_correction(double distance_ft, double offset_ft);

/** Kinetic energy (ft-lb) from bullet weight (grains) and velocity (fps). */
double bcffi_calculate_energy(double bullet_weight_grain, double velocity_fps);

/** Optimal Game Weight from bullet weight (grains) and velocity (fps). */
double bcffi_calculate_ogw(double bullet_weight_grain, double velocity_fps);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // BCLIBC_FFI_H
