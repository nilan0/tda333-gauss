// Double instructions instead of single?


/* reduce matrix A to upper triangular form */
void eliminate (double **A, int N, int B) {
    int i, j, k, I, J;
    /* size of block is (M*M) */
    int M = N/B;
    /* for all block rows */

    for (I = 0; I < N; I += M) {
        br = (I + M) * 4
        /* for all block columns */
        for (J = 0; J < N; J += M) {
            bc = (J + M) * 4
            /* loop over pivot elements */
            for (k = 0; k < Min(br, bc); k += 4, kN += N) {
                //k += A
                max_kJ = Max(k + 1, J)
                /* if pivot element within block */
                if (k >= I && k < br) {
                    kNk = *(kN + k);
                    /* perform calculations on pivot */
                    for (j = max_kJ; j < bc; j++) {
                        kNj = *(kN + j)
                        kNj = kNj / kNk
                    }
                    /* if last element in row */
                    if (j == NA) {
                        kNk = 1.0;
                    }
                }
                /* for all rows below pivot row within block */
                for (i = Max(k + 1, I); i < br; i++, iN += N) {
                    iNk = *(iN + k)
                    /* for all elements in row within block */
                    for (j = max_kJ; j < bc; j++) {
                        iNj = iN + j
                        iNj = iNj - iNk * *(kN + j)
                    }
                    /* if last element in row */
                    if (j == NA) {
                        iNk = 0.0;
                    }
                }
            }
        }
    }
}