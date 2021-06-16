#include <stdlib.h>
#include <stdio.h>
#include <arpa/inet.h>
#include "pardump.h"


partmass_t *
ntoh_particle(partmass_t *p)
{
    uint32_t *word = (uint32_t *)p ; 
    partmass_t *swapped =0 ;

    swapped = (partmass_t *)malloc(sizeof(partmass_t)) ; 
    uint32_t *swapped_word = (uint32_t *)swapped ; 

    for (int i=0; i<(sizeof(partmass_t)/sizeof(uint32_t)); i++)
    {
        *swapped_word++ = ntohl(*word++) ; 
    }

    return swapped;
}

particle_dump_header_t *
ntoh_dump(particle_dump_header_t *p)
{
    uint32_t *word = (uint32_t *)p ; 
    particle_dump_header_t *swapped =0 ;

    swapped = (particle_dump_header_t *)malloc(sizeof(particle_dump_header_t)) ; 
    uint32_t *swapped_word = (uint32_t *)swapped ; 

    for (int i=0; i<(sizeof(particle_dump_header_t)/sizeof(uint32_t)); i++)
    {
        *swapped_word++ = ntohl(*word++) ; 
    }

    return swapped;
}

partmass_t *
read_particles(FILE *fh, int n)
{
    partmass_t *particle ; 

    particle = (partmass_t *)malloc(PARTICLE_SIZE*n) ; 
    if (particle) {
        fread(particle, PARTICLE_SIZE, n, fh) ; 
    }
    return particle ; 
}

particle_dump_t *
read_particle_dump(FILE *fh)
{
    particle_dump_t *pd ; 
    particle_dump_header_t *hdr;
    unsigned int n_particles = 0 ;
    
    
    pd  = (particle_dump_t *)malloc(sizeof(particle_dump_t)) ; 
    hdr = (particle_dump_header_t *)malloc(sizeof(particle_dump_header_t)) ; 
    if (pd && hdr) { 
        pd->header = hdr ; 
        fread(hdr, sizeof(particle_dump_header_t), 1, fh) ; 

        /* get the number of particles but switch endianness */
        n_particles = ntohl(hdr->n_particles) ; 

        /* read the actual particles */
        pd->particles = read_particles(fh, n_particles) ; 
      
    }
    return pd ;
}

void 
print_particle_dump(particle_dump_t *pd)
{
    particle_dump_header_t *hdr = pd->header ; 
    printf("Number of particles: %d\n", ntohl(hdr->n_particles)) ; 
    printf("Number of pollutants: %d\n", ntohl(hdr->n_pollutants)) ; 
    printf("Time of dump: %4d-%02d-%02d %02d:%02d\n",
             ntohl(hdr->year)+2000, ntohl(hdr->month), ntohl(hdr->day),
             ntohl(hdr->hour), ntohl(hdr->minute)) ; 
}

void 
print_particle_dump_raw(particle_dump_t *pm) 
{
    particle_dump_header_t *swapped = ntoh_dump(pm->header) ; 
    uint32_t *printable = (uint32_t *)swapped ; 
    for (int i=0; i < (sizeof(particle_dump_header_t)/sizeof(uint32_t)); i++) 
    {
        float *pfloat ;
        pfloat = (float *)printable ; 
        printf("%d: %u %f\n", i, *(printable++), *pfloat) ; 
    } 
    free(swapped) ; 
}

void 
print_particle(partmass_t *pm)
{
    partmass_t *printable = ntoh_particle(pm) ; 
    printf("(%f, %f) %fm %f(mass units) %us\nPollutant: %u; Sigma-h: %f\nVel w/v: %f/%f\n", 
        printable->particle.lon, printable->particle.lat, printable->particle.height,
        printable->mass[0], printable->particle.age,
        printable->particle.pollutant, printable->particle.sigma_h,
        printable->particle.vel_w, printable->particle.vel_v);

    free(printable) ; 
}

void 
print_particle_raw(partmass_t *pm) 
{
    partmass_t *swapped = ntoh_particle(pm) ; 
    uint32_t *printable = (uint32_t *)swapped ; 
    for (int i=0; i < (sizeof(partmass_t)/sizeof(uint32_t)); i++) 
    {
        float *pfloat ;
        pfloat = (float *)printable ; 
        printf("%d: %u %f\n", i, *(printable++), *pfloat) ; 
    } 
    free(swapped) ; 
}

void
free_particle_dump(particle_dump_t *pd)
{
    if (pd) 
    {
        free(pd->header) ; 
        free(pd->particles) ; 
        free(pd) ; 
    }
}

int 
main(int ac, char **av) 
{ 
    /* usage statement */
    if (ac != 2) {
        printf("Usage: %s <pardump_file>\n", av[0]) ; 
        return -1 ; 
    }

    /* open file */
    FILE *fh = fopen(av[1], "rb") ; 
    if (!fh) { 
        printf("Could not open file: %s\n", av[1]) ; 
        return -2;
    }

    printf("Size of partmass_t in words: %d\n", sizeof(partmass_t)/4) ; 

    /* skip undocumented dummy field */
    uint32_t dummy =0 ; 
    fread(&dummy, sizeof(dummy), 1, fh) ; 

    /* read first particle dump */
    particle_dump_t *first = read_particle_dump(fh) ; 

    print_particle_dump(first) ; 
    print_particle(first->particles) ; 
    print_particle(first->particles+2) ; 

    /* free memory and close files */
    free(first) ; 
    fclose(fh) ; 

    return 0 ; 
}
