#include <stdint.h>

/* 
 * Data type to hold the static part of the particle information. 
 * The particle mass is not included because it is an array of 
 * variable size.
 */
typedef struct 
{
    uint32_t dummy1;        /* undocumented extra item */
    uint32_t dummy2;        /* undocumented extra item */

    float lat ;            /* latitude */
    float lon ;            /* longitude*/
    float height;          /* height AGL (m) */
    float sigma_h ;     
    float vel_w;           /* vertical turbulent velocity (m/s) */
    float vel_v;           /* horizontal turbulent velocity (m/s) */

    uint32_t dummy3;        /* undocumented extra item */
    uint32_t dummy4;        /* undocumented extra item */

    uint32_t age ;          /* particle age (s) */
    uint32_t distribution;  
    uint32_t pollutant ;    /* Nth pollutant species in CONTROL file */
    uint32_t meteo_grid;    /* Nth meteorological grid in CONTROL file */
    uint32_t sort_index ;   /* HYSPLIT internal housekeeping */

    uint32_t dummy5;        /* undocumented extra item */
    uint32_t dummy6;        /* undocumented extra item */
} particle_nomass_t ; 

/*
 * General case of particle data, where any number of masses may be 
 * stored.
 */
typedef struct 
{ 
    float             *mass ;    /* pointer to array of masses */
    particle_nomass_t *particle ;/* pointer to particle data */ 
} particle_t ; 

/* 
 * Special case of particle data where one mass is stored.
 */
typedef struct 
{
    float              mass ;    /* mass data (not a pointer */
    particle_nomass_t  particle; /* particle data (not a pointer) */
} particle_onemass_t ; 

/* 
 * Macro to define arbitrary mass array length. 
 */
#define PARTICLE(N_MASS) struct { float mass[N_MASS]; particle_nomass_t particle; } 


/* 
 * Fixed size particle structures (hard-coded)
 */
#define MASS_PER_PARTICLE 1
typedef PARTICLE(MASS_PER_PARTICLE) partmass_t ; 
#define PARTICLE_SIZE (sizeof(partmass_t))


typedef struct
{
    uint32_t n_particles ;  /* number of particles */
    uint32_t n_pollutants;  /* number of pollutants per particle */
    uint32_t year ;         /* time of particle dump (year) */
    uint32_t month ;        /* time of particle dump (month) */
    uint32_t day ;          /* time of particle dump (day) */
    uint32_t hour ;         /* time of particle dump (hour) */
    uint32_t minute ;       /* time of particle dump (minute) */
    uint32_t dummy1 ; 	    /* undocumented */
    uint32_t dummy2 ; 	    /* undocumented */
} particle_dump_header_t ; 

typedef struct
{
    particle_dump_header_t *header ; /* header data */
    partmass_t *particles;  /* particle data for this dump */
} particle_dump_t ; 
