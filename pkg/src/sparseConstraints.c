
#include <stdlib.h>
#include <math.h>
#include "sparseConstraints.h"


SparseConstraints * sc_new( int m ){
    
    SparseConstraints *E;
    E = (SparseConstraints *) calloc(1, sizeof(SparseConstraints));
    E->nedits = m;
    E->A = (double **) calloc(E->nedits, sizeof(double *));
    E->index = (int **) calloc(E->nedits, sizeof(int *));
    E->nrag = (int *) calloc(E->nedits, sizeof(int));
    E->b = (double *) calloc(E->nedits, sizeof(double));
    return E;
}

void sc_del(SparseConstraints *E){
    free(E->b);
    free(E->nrag);
    for ( int i = 0; i < E->nedits; i++){
        free(E->A[i]);
        free(E->index[i]);
    } 
    free(E);
}

// generate SparseConstraints object from dense matrix
SparseConstraints * sc_from_matrix(double *A, double *b, int m, int n, int neq, double tol){
    int nrag, jrag;

    SparseConstraints *E = sc_new(m);
    E->neq = neq;
    E->nvar = n;
    for ( int i=0; i < E->nedits; i++){
        E->b[i] = b[i];
        nrag=0;
        jrag=0;      
        for ( int j=0; j < n; j++ ){
            if ( fabs(A[i + m*j]) > tol ) ++nrag;
        }
        E->nrag[i] = nrag;
        E->A[i] = (double *) calloc(nrag, sizeof(double));
        E->index[i] = (unsigned int *) calloc(nrag, sizeof(unsigned int));
        for ( int j=0; j<n; j++ ){
            if ( fabs(A[i+m*j]) > tol ){
                E->index[i][jrag] = j;
                E->A[i][jrag] = A[i + m*j];
                ++jrag;
            }
        }
    }
    return E;
}




static int get_row_end(int *rows, int nrows, int row_start){
    int row_nr = rows[row_start];
    int row_end = row_start-1;
    while (row_end < (nrows-1) && rows[row_end+1] == row_nr) row_end++;
    return row_end;
}



// generate SparseConstraints from row-column-coefficient specifications
// It is assumed that  int *rows is sorted in increasing order!
SparseConstraints * sc_from_sparse_matrix(int *rows, int *cols, double *coef, int ncoef, double *b, int m, int neq ){

    SparseConstraints *E = sc_new(m);
    int maxcol=0, k;
    int row_start = 0, row_nr; 
    int row_end = get_row_end(rows, ncoef, row_start);
    for ( int irow=0; irow < m; irow++){
            E->b[irow] = b[irow];
            row_nr = rows[row_start];
            row_end = get_row_end(rows, ncoef, row_start);
           
 Rprintf("  irow: %d, row_start: %d, row_end: %d\n",irow,row_start,row_end);

            E->nrag[irow]    = 1 + row_end - row_start;
            E->index[irow]   = (int *) calloc( E->nrag[irow], sizeof(int));
            E->A[irow]       = (double *) calloc( E->nrag[irow], sizeof(double));
            k = 0;
            for ( int j=row_start; j <= row_end; j++){
                E->A[irow][k] = coef[j];
                E->index[irow][k] = cols[j];
                ++k;
                maxcol = cols[j] > maxcol ? cols[j] : maxcol;
            }
            row_start = row_end+1;
    } 
    
    E->neq = neq;
    E->nvar = maxcol;

    return E;

}





