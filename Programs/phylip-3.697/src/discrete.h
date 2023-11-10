
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
  discrete.h: included in pars
*/

typedef struct gbases {
  discbaseptr discbase;
  struct gbases *next;
} gbases;

struct LOC_hyptrav {
  boolean bottom;
  node *r;
  discbaseptr hypset;
  boolean maybe, nonzero;
  unsigned char tempset, anc;
} ;


extern long nonodes, endsite, outgrno, nextree, which;
extern boolean interleaved, printdata, outgropt, treeprint, dotdiff;
extern steptr weight, category, alias, location, ally;
extern sequence y, convtab;


#ifndef OLDC
/*function prototypes*/
void   inputdata(long);
void   alloctree(pointarray *, long, boolean);
void   setuptree(pointarray, long, boolean);
void   alloctip(node *, long *, unsigned char *);
void   sitesort(long, steptr);
void   sitecombine(long);
void   sitescrunch(long);

void   makevalues(pointarray, long *, unsigned char *, boolean);
void   fillin(node *, node *, node *);
long   getlargest(long *);
void   multifillin(node *, node *, long);
void   sumnsteps(node *, node *, node *, long, long);
void   sumnsteps2(node *, node *, node *, long, long, long *);
void   multisumnsteps(node *, node *, long, long, long *);
void   multisumnsteps2(node *);
void   findoutgroup(node *, boolean *);
boolean alltips(node *, node *);

void   gdispose(node *, node **, pointarray);
void   preorder(node *, node *, node *, node *, node *, node *, long );
void   updatenumdesc(node *, node *, long);
void   add(node *, node *, node *, node **, boolean, pointarray,
           node **, long *, unsigned char *);
void   findbelow(node **, node *, node *);
void   re_move(node *, node **, node **, boolean, pointarray,
               node **, long *, unsigned char *);
void   postorder(node *);
void   getnufork(node **, node **, pointarray, long *, unsigned char *);
void   reroot(node *, node *);
void   reroot2(node *, node *);

void   reroot3(node *, node *, node *, node *, node **);
void   savetraverse(node *);
void   newindex(long, node *);
void   flipindexes(long, pointarray);
boolean parentinmulti(node *);
long   sibsvisited(node *, long *);
long   smallest(node *, long *);
void   bintomulti(node **, node **, node **, long *, unsigned char *);
void   backtobinary(node **, node *, node **);
boolean outgrin(node *, node *);

void   flipnodes(node *, node *);
void   moveleft(node *, node *, node **);
void   savetree(node *, long *, pointarray, node **, long *,
                unsigned char *);
void   addnsave(node *, node *, node *, node **, node **, boolean multf,
                pointarray , long *, long *, unsigned char *);
void   addbestever(long *, long *, long, boolean, long *, bestelm *);
void   addtiedtree(long, long *, long, boolean, long *, bestelm *);
void   clearcollapse(pointarray);
void   clearbottom(pointarray);
void   collabranch(node *,node *,node *);
boolean allcommonbases(node *, node *, boolean *);

void    findbottom(node *, node **);
boolean moresteps(node *, node *);
boolean passdown(node *, node *, node *, node *, node *, node *, node *,
                node *, node *, boolean);
boolean trycollapdesc(node *, node *, node *, node *, node *, node *,
                node *, node *, node *, boolean ,long *, unsigned char *);
void   setbottom(node *);
boolean zeroinsubtree(node *, node *, node *, node *, node *, node *,
                node *, node *, boolean , node *, long *, unsigned char *);
boolean collapsible(node *, node *, node *, node *, node *, node *, node *, 
                node *, boolean , node *, long *, unsigned char *, pointarray);
void   replaceback(node **,node *,node *,node **,long *,unsigned char *);
void   putback(node *, node *, node *, node **);
void   savelocrearr(node *, node *, node *, node *, node *, node *,
                node *, node *, node *, node **, long, long *, boolean, boolean,
                boolean *, long *, bestelm *, pointarray, node **, long *,
                unsigned char *);

void   clearvisited(pointarray);
void   hyprint(long,long,struct LOC_hyptrav *, pointarray);
void   gnubase(gbases **, gbases **, long);
void   chuckbase(gbases *, gbases **);
void   hyptrav(node *, discbaseptr, long, long, boolean, pointarray,
                gbases **);
void   hypstates(long, node *, pointarray, gbases **);
void   initbranchlen(node *);
void   initmin(node *, long, boolean);
void   initbase(node *, long);
void   inittreetrav(node *, long);

void   compmin(node *, node *);
void   minpostorder(node *, pointarray);
void   branchlength(node *, node *, double *, pointarray);
void   printbranchlengths(node *);
void   branchlentrav(node *, node *, long, long, double *, pointarray);
void   treelength(node *, long, pointarray);
void   coordinates(node *, long *, double , long *);
void   drawline(long, double, node *);
void   printree(node *, double);
void   writesteps(long, boolean, steptr, node *);

void   treeout(node *, long, long *, node *);
void   drawline3(long, double, node *);
void   standev(long, long, long, double, double *, long **, longer);
void   freetip(node *);
void   freenontip(node *);
void   freenodes(long, pointarray);
void   freenode(node **);
void   freetree(long, pointarray);
void   freegarbage(gbases **);
void   freegrbg(node **);
void treeout3(node *p, long nextree, long *col, node *root);

void   collapsetree(node *, node *, node **, pointarray, long *, unsigned char *);
void   collapsebestrees(node **, node **, pointarray, bestelm *, long *, 
                        long *, unsigned char *, long, boolean, boolean);
/*function prototypes*/
#endif
