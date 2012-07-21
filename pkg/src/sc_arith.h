
#ifndef rspa_scarith
#define rspa_scarith


// multiply row of constraints with vector
double sc_row_vec(SparseConstraints *E, int i, double *x);


// multiply constraints with vector
void sc_multvec(SparseConstraints *E, double *x, double *Ax);


// compute difference vector Ax - b
void sc_diffvec(SparseConstraints *E, double *x, double *diff);

/* Compute sum  sum(|Ax-b|) for equations.
 * For inequations, if diff_i = a_i.x - b < 0 then diff_i = 0
 *  
 *  diff is room to compute difference vector
 * 
 */
double sc_diffsum(SparseConstraints *E, double *x);

// substitute a value for one of the variables. 
// returns the number of substitutions.
// This just does A[,i] = 0 and b  = b-A[,i]*val
// Empty rows are not removed.
int sc_substvalue(SparseConstraints *, int, double );

#endif
