from struct import pack, unpack, calcsize ; 
from datetime import datetime, timedelta ; 
from functools import partial ; 

#
# Models hysplit particles in particle dumps. 
# Reads and writes from particle dump files. 
# writes to buffer suitable for upload to PostGIS 
# database.
#
class Particle (object) : 
    _pardump_format_no_mass = "!" + "f"*6 + "i"*5

    def __init__(self) : 
        self._pollutant_mass = None
        self._lat = None
        self._lon = None
        self._height = None
        self._sigma_h = None
        self._vel_w = None
        self._vel_v = None
        self._age = None
        self._distribution = None
        self._pollutant = None
        self._meteo_grid = None
        self._sort_index = None

    @staticmethod
    def ReadPardump(file_object, num_pollutants) : 
        mass_format = "!" + "f"*num_pollutants
        buf = file_object.read(calcsize(mass_format))
        new_obj = Particle()
        new_obj._pollutant_mass = unpack(buf, mass_format)

        buf = file_object.read(calcsize(Particle._pardump_format_no_mass))
        (new_obj._lat, new_obj._lon, new_obj._height,
            new_obj._sigma_h, new_obj._vel_w, new_obj._vel_v,
            new_obj._age, new_obj._distribution, new_obj._pollutant, 
            new_obj._meteo_grid, new_obj._sort_index) = \
            unpack(Particle._pardump_format_no_mass, buf)
        return new_obj

    @property
    def empty(self) : 
        """Returns true if this object is uninitialized"""
        return self._pollutant_mass is None

    @property
    def dead(self):  
        """Returns true if this object has lat/lon==0, a flag for particle not in use."""
        return (self._lat==0) and (self._lon == 0)

    @property
    def num_pollutants(self) : 
        return len(self._pollutant_mass)

    @property
    def mass(self) : 
        """Tuple of pollutant masses. Number of pollutants per particle is set 
        by MAXDIM. Default is 1."""
        return self._pollutant_mass

    @property 
    def lat(self) : 
        """Particle/puff latitude"""
        return self._lat

    @property
    def lon(self) : 
        """particle/puff longitude"""
        return self._lon

    @property
    def height(self) : 
        """HEIGHT is in meters agl. The height is in agl even when KMSL=1 
           is set in SETUP.CFG Note that there may be some differences between 
           the value written to the pardump file and the actual value when the 
           terrain height is large. The terrain height is not passed to the 
           pardump reading or writing routines and so the height is written 
           approximating terrain height as 0m. This results in a small difference 
           which is dependent on the terrain height and internal scaling height."""
        return self._height

    @property
    def sigma_h(self) : 
        """SIGMA-H is the horizontal puff size in meters."""
        return self._sigma_h

    @property
    def vel_w(self) :
        """VEL-W is the current value for the turbulent velocity in the vertical in m/s"""
        return self._vel_w

    @property
    def vel_v(self) : 
        """VEL-V is the current value for the turbulent velocity in the horizontal in m/s.
           Currently VEL-U is not written to the pardump file and when the model is 
           initialized from a pardump file, it assumed that vel-u = vel-v."""
        return self._vel_v

    @property
    def age(self) : 
        """particle age in seconds"""
        return self._age

    @property
    def age_timedelta(self) : 
        return timedelta(seconds=self.age)

    @property
    def distribution(self) :
        return self._distribution

    @property
    def pollutant(self) : 
        """POLLUTANT is an integer, N, which corresponds to the Nth pollutant 
           species defined in the CONTROL file."""
        return self._pollutant

    @property
    def meteo_grid(self) : 
        """METEO-GRID is n integer, N, which corresponds to the Nth meteorological 
           data grid defined in the CONTROL file."""
        return self._meteo_grid

    @property
    def sort_index(self) : 
        """Each particle or puff is assigned its own unique sort-index. 
           The sort index is used within HYSPLIT for looping through all the 
           computational particles or puffs. If a computational particle is 
           removed during the simulation, the sort indices are reassigned so 
           that there are only as many sort indices as particles. Consequently, 
           the sort index for a computational particle may change during a simulation. 
           If ichem=8, then particle deletion is turned off, and the sort index will 
           refer to the same computational particle throughout the simulation. In 
           the case of puffs, the sort indices are reassigned when puffs are deleted, 
           merged or split."""
        return self._sort_index    
        
    
class ParticleDump(object) : 
    """Essentially represents a list of particles with a given number of pollutants
       at a specific time."""

    _pardump_format = "!" + "i"*7

    def __init__(self) : 
        self._year = None
        self._month = None
        self._day   = None
        self._hour  = None
        self._minute  = None
        self._maxdim  = None
        self._particles = None

    @staticmethod
    def ReadPardump(file_object) :
        new_obj = ParticleDump()
        try: 
            buf = file_object.read(calcsize(ParticleDump._pardump_format))
            (num_particles, new_obj._maxdim,
                  new_obj._year, new_obj._month, new_obj._day, 
                  new_obj._hour, new_obj._minute) = unpack(ParticleDump._pardump_format, buf)
            new_obj._year += 2000
            new_obj._particles = [] 
            for i in range(num_particles) : 
                new_obj._particles.append(Particle.ReadPardump(file_object, new_obj._maxdim))
        except : 
            if new_obj.empty: 
                new_obj = None
        return new_obj
        
    @property
    def empty(self) : 
        return self._particles is None

    @property
    def num_particles(self) : 
        """Number of particles in this dump"""
        return len(self._particles)

    @property
    def num_pollutants(self) : 
        """Number of pollutants per particle is set by MAXDIM. Default is 1."""
        return self._maxdim

    @property
    def year(self) : 
        """Returns 4 digit year. Stored as 2 digit year in PARDUMP file."""
        return self._year

    @property
    def month(self) : 
        return self._month

    @property
    def day(self) : 
        return self._day

    @property
    def hour(self) : 
        return self._hour

    @property
    def minute(self) : 
        return self._minute

    @property
    def timestamp(self) : 
        return datetime(self.year, self.month, self.day, self.hour, self.minute)

def ReadPardumpFile(fname)  :
    particle_dump_list = [] 
    with open(fname, 'rb') as pardump : 
        #discard undocumented leading 4 bytes.
        pardump.read(4)

        for particle_dump in iter(partial(ParticleDump.ReadPardump,pardump), None) : 
            particle_dump_list.append(particle_dump)

    return particle_dump_list
