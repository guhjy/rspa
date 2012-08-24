
#ifndef rspa_maxd
#define rspa_maxd

double maxdist(double *, double *, int);

double absmax(double *, double *, int, int);

double dc_diffmax(double *A, double *b, double *x, int m, int n);

// test if a vector is finite everywhere
int diverged(double *, int);

#endif

