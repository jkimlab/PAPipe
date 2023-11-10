/* version 3.696.
   Written by Joseph Felsenstein and Michal Palzewski.

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

#include "phylip.h"

#include "seq.h"
#include "mlclock.h"

/* Define the minimum branch length to be enforced for clocklike trees */
const double MIN_BRANCH_LENGTH = 1e-6;

/* MIN_ROOT_TYME is added to the current root tyme and used as the lower
 * bound when optimizing at the root. */
const double MIN_ROOT_TYME     = -10;

static evaluator_t evaluate = NULL;
static tree *curtree = NULL;                   /* current tree in use */
static node *current_node = NULL;              /* current node being optimized */

static double cur_node_eval(double x);
static double evaluate_tyme(tree *t, node *p, double tyme);


void
mlclock_init(tree *t, evaluator_t f)
{
  curtree = t;
  evaluate = f;
}


boolean
all_tymes_valid(node *p, double minlength, boolean fix)
{
  /* Ensures that all node tymes at node p and descending from it are
   * valid, with all branches being not less than minlength. If any
   * inconsistencies are found, returns true. If 'fix' is given,
   * adjustments are made to make the subtree consistent. Otherwise if
   * assertions are enabled, all inconsistencies are fatal. No effort is
   * made to check that the parent node tyme p->back->tyme is less than
   * p->tyme. */

  node *q;
  double max_tyme;
  boolean ret = true;

  /* All tips should have tyme == 0.0 */
  if ( p->tip ) {
    if ( p->tyme == 0.0 )
      return true;
    else { /* this would be very bad. */
      if ( fix ) 
        p->tyme = 0.0;
      else
        assert( p->tyme == 0 );

      return false;
    }
  }      

  for ( q = p->next; q != p; q = q->next ) {
    /* All nodes in ring should have same tyme */
    if ( q && q->tyme != p->tyme ) {
      if ( fix )
        q->tyme = p->tyme;
      else
        assert( q->tyme == p->tyme );
      ret = false;
    }

    /* All subtrees should be OK too */
    if (!q->back)
      continue;
    if ( all_tymes_valid(q->back, minlength, fix) == false )
      ret = false;
  }
  
  /* Tymes cannot be greater than the minimum child time, less
   * branch length */
  max_tyme = min_child_tyme(p) - minlength;
  if ( p->tyme > max_tyme ) {
    if ( fix )
      setnodetymes(p, max_tyme);
    else
      assert( p->tyme < max_tyme );
    return false;
  }

  return ret;
}


void
setnodetymes(node* p, double newtyme)
{ /* Set node tyme for an entire fork. Also clears initialized flags on this 
   * fork, but not recursively. inittrav() must be called before evaluating
   * elsewhere. */
  node * q;

  curtree->likelihood = UNDEFINED;
  p->tyme = newtyme;
  p->initialized = false;
  if ( p->tip ) return;
  for ( q = p->next; q != p; q = q->next ) {
    assert(q);
    q->tyme = newtyme;
    q->initialized = false;
  }
} /* setnodetymes */


double
min_child_tyme(node *p)
{
  /* Return the minimum tyme of all children. p must be a parent nodelet */
  double min;
  node *q;

  min = 1.0; /* Tymes are always nonpositive */
  
  for ( q = p->next; q != p; q = q->next ) {
    if ( q->back == NULL ) continue;
    if ( q->back->tyme < min )
      min = q->back->tyme;
  }
  
  return min;
} /* min_child_tyme */


double
parent_tyme(node *p) 
{
  /* Return the tyme of the parent of node p. p must be a parent nodelet. */
  if ( p->back ) {
    return p->back->tyme;
  } else {
    return p->tyme + MIN_ROOT_TYME;
  }
} /* parent_tyme */


boolean
valid_tyme(node *p, double tyme)
{
  /* Return true if tyme is a valid tyme to assign to node p. tyme must be
   * finite, not greater than any of p's children, and not less than p's
   * parent. Also, tip nodes can only be assigned 0. Otherwise false is
   * returned. */

  /* p must be the parent nodelet of its node group. */

  assert( p->tip != true || tyme == 0.0 );
  assert( tyme <= min_child_tyme(p) );
  assert( tyme >= parent_tyme(p) );

  return true;
} /* valid_tyme */


static long
node_max_depth(tree *t, node *p)
{
  /* Return the largest number of branches between node p and any tip node. */ 
  long max_depth = 0;
  long cdep;
  node *q;

  assert(p = pnode(t, p));

  if (p->tip)
    return 0;

  for (q = p->next; q != p; q = q->next) {
    cdep = node_max_depth(t, q->back) + 1;
    if (cdep > max_depth)
      max_depth = cdep;
  }
  return max_depth;
}


static double
node_max_tyme(tree *t, node *p)
{
  /* Return the absolute maximum tyme a node can be pushed to. */
  return -node_max_depth(t, p) * MIN_BRANCH_LENGTH;
}


void
save_tymes(tree* save_tree, double tymes[])
{
  /* Save the current node tymes of save_tree in tymes[]. tymes must point to
   * an array of (nonodes - spp) elements. Tyme for node i gets saved in
   * tymes[i-spp]. */

  int i;
  assert( all_tymes_valid(curtree->root, 0.0, false) );
  for ( i = spp ; i < nonodes ; i++) {
    tymes[i - spp] = save_tree->nodep[i]->tyme;
  }
}


void
restore_tymes(tree *load_tree, double tymes[])
{
  /* Restore the tymes saved in tymes[] to tree load_tree. See save_tymes()
   * */

  int i;
  for ( i = spp ; i < nonodes ; i++) {
    if (load_tree->nodep[i]->tyme != tymes[i-spp])
      setnodetymes(load_tree->nodep[i], tymes[i-spp]);
  }
  /* Check for invalid tymes */
  assert( all_tymes_valid(curtree->root, 0.0, false) );
}


static void
push_tymes_to_root(tree *t, node *p, double tyme)
{
  /* Set tyme for node p to tyme. Ancestors of p are moved down if necessary to prevent
   * negative branch lengths. */
  node *q, *r;

  assert(p = pnode(t, p));

  setnodetymes(p, tyme);

  r = p;
  while (r->back != NULL) {
    q = pnode(t, r->back); /* q = parent(r); */
    if (q->tyme > r->tyme - MIN_BRANCH_LENGTH)
      setnodetymes(q, r->tyme - MIN_BRANCH_LENGTH);
    else
      break;
    r = q;
  }
}


static void
push_tymes_to_tips(tree *t, node *p, double tyme)
{
  /* Set tyme for node p to tyme. Descendants of p are moved up if necessary to
   * prevent negative branch lengths. */

  node *q;

  assert( p == pnode(t, p) );

  setnodetymes(p, tyme);

  for (q = p->next; q != p; q = q->next) {
    if (q->back->tyme < p->tyme + MIN_BRANCH_LENGTH) {
      if (q->back->tip && q->back->tyme < p->tyme) {
        fprintf(stderr,
            "Error: Attempt to move node past tips.\n"
            "%s line %d\n", __FILE__, __LINE__);
        exxit(-1);
      }
      else {
        if(!( q->back->tip ) ) {
          push_tymes_to_tips(t, q->back, p->tyme + MIN_BRANCH_LENGTH);
        }
      }
    }
  }
}


static void
set_tyme(tree *t, node *p, double tyme)
{
  /* Set the tyme for node p, pushing others out of the way */

  /* Use rootward node in fork */
  p = pnode(t, p);

  /* Set node tyme and push other nodes out of the way */
  if (tyme < p->tyme)
    push_tymes_to_root(t, p, tyme);
  else
    push_tymes_to_tips(t, p, tyme);

}


static double 
evaluate_tyme(tree *t, node *p, double tyme)
{
  /* Evaluate curtree if node p is at tyme. Return the score. Leaves original
   * tymes intact. */
  static double *savetymes = NULL;
  static long savetymes_sz = 0;

  long nforks = nonodes - spp;
  double score = 1.0;

  if (savetymes_sz < nforks + 1) {
    if (savetymes != NULL)
      free(savetymes);
    savetymes_sz = nforks;
    savetymes = (double *)Malloc(savetymes_sz * sizeof(double));
  }

  /* Save the current tymes */
  save_tymes(t, savetymes);

  set_tyme(t, p, tyme);

  /* Evaluate the tree */
  score = evaluate(p);

  /* Restore original tymes */
  restore_tymes(t, savetymes);

  assert( all_tymes_valid(curtree->root, 0.0, false) );

  return score;
}


static double
cur_node_eval(double x)
{
  return evaluate_tyme(curtree, current_node, x);
}


double
maximize(double min_tyme, double cur, double max_tyme, double(*f)(double),
    double eps, boolean *success)
{
  /* Find the maximum of function f by parabolic interpolation and golden section search.
   * (based on Brent method in NR) */

  /* [min_tyme, max_tyme] is the domain, cur is the best guess and must be
   * within the domain, eps is the fractional accuracy of the result, i.e. the
   * returned value x will be accurate to +/- x*eps. */

  boolean bracket = false;
  static long max_iterations = 100;              /* maximum iterations */
  
  long it;                                      /* iteration counter */
  double x[3], lnl[3];                          /* tyme (x) and log likelihood
                                                   (lnl) points below, at, and
                                                   above the current tyme */
  double xn, yn;                                /* New point */
  double d;                                     /* delta x to new point */
  double mid;                                   /* Midpoint of (x[0], x[2]) */
  
  double xmax, lnlmax;

  double tdelta;                                /* uphill step for bracket
                                                   finding */
  double last_d = 0.0;
  double prec;                                  /* epsilon * tyme */
  double t1, t2, t3, t4;                        /* temps for parabolic fit */

  /* Bracket our maximum; We will assume that we are already close and move
   * uphill by exponentially increasing steps until we find a smaller value.
   * The initial step should be small to allow us to finish quickly if we're
   * still on the maximum from previous smoothings */
  x[1] = cur;
  tdelta = fabs(10.0 * cur * eps);
  x[0] = cur - tdelta;
  if (x[0] < min_tyme)
    x[0] = min_tyme;

  lnl[1] = (*f)(x[1]);
  lnl[0] = (*f)(x[0]);
 
  if (lnl[0] < lnl[1]) {
    do {
      x[2] = x[1] + tdelta;
      if (x[2] > max_tyme)
        x[2] = max_tyme;
      lnl[2] = (*f)(x[2]);
      if (lnl[2] < lnl[1])
        break;
      x[0] = x[1]; lnl[0] = lnl[1];
      x[1] = x[2]; lnl[1] = lnl[2];
      tdelta *= 2;
    } while (x[2] < max_tyme);
  }
  else { /* lnl[0] > lnl[1] */
    /* shift points (0, 1) -> (1, 2) */
    x[2] = x[1]; x[1] = x[0];
    lnl[2] = lnl[1]; lnl[1] = lnl[0];
    do {
      x[0] = x[1] - tdelta;
      if (x[0] < min_tyme)
        x[0] = min_tyme;
      lnl[0] = (*f)(x[0]);
      if (lnl[0] < lnl[1])
        break;
      x[2] = x[1]; lnl[2] = lnl[1];
      x[1] = x[0]; lnl[1] = lnl[0];
      tdelta *= 2;
    } while (x[0] > min_tyme);
  }

  /* FIXME: this should not be necessary. Somewhere we fail to enforce
   * MIN_BRANCH_LENGTH */
  if ( x[1] < x[0] || x[2] < x[1] ) {
    x[1] = (x[2] + x[0]) / 2.0;
    lnl[1] = (*f)(x[1]);
  }
  assert(x[0] <= x[1] && x[1] <= x[2]);

  xmax = x[1];
  lnlmax = lnl[1];
  if (lnl[0] > lnlmax) {
    xmax = x[0];
    lnlmax = lnl[0];
  }
  if (lnl[2] > lnlmax) {
    xmax = x[2];
    lnlmax = lnl[2];
  }

  bracket = false;
  for (it = 0; it < max_iterations; it++) {
    assert(x[0] <= x[1] && x[1] <= x[2]);
    prec = fabs(x[1] * eps) + 1e-7;

    if (x[2] - x[0] < 4.0*prec)
      break;

    d = 0.0;
    mid = (x[2] + x[0]) / 2.0;

    if (lnl[0] < lnl[1] && lnl[1] > lnl[0]) {
      /* We have a bracket */
      bracket = true;

      /* Try parabolic interpolation */
      t1 = (x[1] - x[0]) * (lnl[1] - lnl[2]);
      t2 = (x[1] - x[2]) * (lnl[1] - lnl[0]);

      t3 = t1*(x[1] - x[0]) - t2*(x[1] - x[2]);
      t4 = 2.0*(t1 - t2);

      if (t4 > 0.0)
        t3 = -t3;
      t4 = fabs(t4);

      if ( fabs(t3) < fabs(0.5*t4*last_d)
           && t3 > t4 * (x[0] - x[1])
           && t3 < t4 * (x[2] - x[1]) )
      {
        d = t3 / t4;
        xn = x[1] + d;
        /* Keep the new point from getting too close to the end points */
        if (xn - x[0] < 2.0*prec || x[2] - xn < 2.0*prec)
          d = xn - mid > 0 ? -prec : prec;
      } 
    } else {
      /* We should never lose our bracket once we've found it. */
      assert( !bracket );
    }
      
    if (d == 0.0) {
      /* Bisect larger interval using golden ratio */
      d = x[1] > mid ? 0.38 * (x[0] - x[1])
                     : 0.38 * (x[2] - x[1]);
    }
    /* Keep the new point from getting too close to the middle one */
    if (fabs(d) < prec)
      d = d > 0 ? prec : -prec;
    xn = x[1] + d;
    last_d = d;
    yn = (*f)(xn);
    if (yn > lnlmax) {
      *success = true;
      xmax = xn;
      lnlmax = yn;
    }

    if (yn > lnl[1]) {
      /* (xn, yn) is the new middle point */
      if (xn > x[1])
        x[0] = x[1];
      else
        x[2] = x[1];
      x[1] = xn; lnl[1] = yn;
    }
    else {
      /* xn is the new bound */
      if (xn > x[1])
        x[2] = xn;
      else
        x[0] = xn;
    }
  }
  return xmax;
}


boolean
makenewv(node *p)
{
  /* Try to improve tree by moving node p. Returns true if a better likelihood
   * was found */
  
  double min_tyme, max_tyme;                    /* absolute tyme limits */
  double new_tyme;                              /* result from maximize() */
  boolean success = false;                      /* return value */
  
  node *s = curtree->nodep[p->index - 1];
 

  assert( valid_tyme(s, s->tyme) );
  
  /* Tyme cannot be less than parent */
  if (s == curtree->root)
    min_tyme = s->tyme + MIN_ROOT_TYME;
  else
    min_tyme = parent_tyme(s) + MIN_BRANCH_LENGTH;

  /* Tyme cannot be greater than any children */
  max_tyme = min_child_tyme(s) - MIN_BRANCH_LENGTH;

  /*
   * EXPERIMENTAL:
   * Allow nodes to move pretty much anywhere by pushing others outta the way.
   */

  /* First, find the absolute maximum and minimum tymes. */
  /* Minimum tyme is somewhere past the root */
  min_tyme = curtree->root->tyme + MIN_ROOT_TYME;
  /* Max tyme is the minimum branch length times the maximal number of branches
   * to any tip node. */
  max_tyme = node_max_tyme(curtree, s);

  /* Nothing to do if we can't move */
  if ( max_tyme < min_tyme + 2.0 * MIN_BRANCH_LENGTH ) {
    return false;
  }

  /* Fix a failure to enforce minimum branch lengths which occurs somewhere in
   * dnamlk_add() */
  if (s->tyme > max_tyme)
    set_tyme(curtree, s, max_tyme);

  current_node = s;
  new_tyme = maximize(min_tyme, s->tyme, max_tyme, &cur_node_eval, epsilon, &success);
    
  set_tyme(curtree, s, new_tyme);
  

  return success;
}  /* makenewv */

