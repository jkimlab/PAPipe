
/* version 3.696.
   Written by Joseph Felsenstein, Akiko Fuseki, Sean Lamont, and Andrew Keeffe.

   Copyright (c) 1993-2014, Joseph Felsenstein
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/

/*
  wagner.h: included in move, mix & penny 
*/

#ifndef OLDC
/* function prototypes */
void   inputmixture(bitptr);
void   inputmixturenew(bitptr);
void   printmixture(FILE *, bitptr);
void   fillin(node2 *,long, boolean, bitptr, bitptr);
void   count(long *, bitptr, steptr, steptr);
void   postorder(node2 *, long, boolean, bitptr, bitptr);
void   cpostorder(node2 *, boolean, bitptr, steptr, steptr);
void   filltrav(node2 *, long, boolean, bitptr, bitptr);
void   hyprint(struct htrav_vars2 *,boolean,boolean,boolean,bitptr,Char *);
void   hyptrav(node2 *, boolean, bitptr, long, boolean, boolean, bitptr,
                bitptr, bitptr, pointptr2, Char *, gbit *);
void   hypstates(long, boolean, boolean, boolean, node2 *, bitptr, bitptr,
                bitptr, pointptr2, Char *, gbit *);

void   drawline(long, double, node2 *);
void   printree(boolean, boolean, boolean, node2 *);
void   writesteps(boolean, steptr);
/* function prototypes */
#endif

