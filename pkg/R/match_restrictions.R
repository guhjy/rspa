#' Alter numeric data records to match linear (in)equality constraints.
#'
#' Apply the successive projection algorithm to adjust each record in 
#' \code{dat} to satisfy a set of linear (in)equality constraints.
#'
#'
#' @param dat A \code{data.frame}
#' @param restrictions An object of class \code{\link[validate]{validator}}
#' @param adjust (optional) A \code{logical} matrix of dimensions
#'   \code{dim(dat)} where \code{TRUE} indicates that a value may be adjusted.
#'   When missing, the \code{\link{tagged_values}} are used. If no tagging was
#'   applied, adjust will default to an all \code{TRUE} matrix with
#'   dimensions equal to \code{dim(dat)}.
#' @param weight A weight vector of length \code{ncol(dat)} or a matrix of dimensions \code{dim(dat)}.
#' @param remove_tag if a value position indicator is present, remove it?
#' @param ... arguments passed to \code{\link[lintools]{project}}.
#' 
#' 
#' @return \code{dat}, with values adapted.
#' 
#' @example ../examples/match_restrictions.R
#' 
#' @seealso \code{\link{tag_missing}}
#' 
#' 
#' @export
match_restrictions <- function(dat, restrictions
      , adjust
      , weight=rep(1,ncol(dat))
      , remove_tag=TRUE
      , ...){
  stopifnot(inherits(dat,"data.frame"))
  stopifnot(inherits(restrictions,"validator"))
  if (missing(adjust)){
    adjust <- tagged_values(dat)
    if (is.null(adjust))
      adjust <- array(TRUE, dim=dim(dat))
  }
  
  if (is.vector(weight)){
    stopifnot(length(weight)==ncol(dat))
    weight <- matrix(rep(weight,times=nrow(dat)),byrow=TRUE,nrow=nrow(dat))
  } else {
    stopifnot(ncol(weight)==ncol(dat))
  }
  colnames(weight) <- colnames(dat)
  
  stopifnot(all(dim(adjust) == dim(dat)))
  colnames(adjust) <- colnames(dat)
  
  # Get linear restrictions, sort in normalized order.
  L <- restrictions$linear_coefficients(normalize=TRUE)
  i <- order(L$operators, decreasing = TRUE)
  L$A <- L$A[i,,drop=FALSE]
  L$b <- L$b[i,,drop=FALSE]
  L$operators <- L$operators[i]
  
  
  # check if all variables in validator occur in the data.
  not_in_dat <- colnames(L$A)[!colnames(L$A) %in% names(dat)]
  if (length(not_in_dat)>0){
    stopf("Validator object uses variables not present in data: %s"
          ,paste(not_in_dat, collapse=", "))
  }
  
  in_res <- names(dat)[names(dat) %in% colnames(L$A)]
  weight <- weight[ , in_res, drop=FALSE]
  adjust <- adjust[ , in_res, drop=FALSE]
  # put columns of A in same order as data.
  L$A <- L$A[,in_res, drop=FALSE]
  # working copy.
  M <- t(dat[in_res])
  
  for ( i in seq_len(ncol(M))){
    adj <- adjust[i,]
    if (!any(adj)) next
    
    x <- M[,i]
    constr <- lintools::subst_value(L$A, L$b, variables=!adj, values=x[!adj])
    
    constr <- lintools::compact(
                  A = constr$A
                , b = constr$b
                , x = x
                , neq = sum(L$operators=="==")
                , nleq = sum(L$operators=="<="))
    
    wt <- weight[i, names(constr$x)]
    out <- lintools::project(x = constr$x
                  , A = constr$A
                  , b = constr$b
                  , neq = constr$neq
                  , w = wt, ...)
    if (out$status > 0){
      warnf("no convergence in record number %d: %s",i,CONV_MSG[out$status])
    }
    M[names(constr$x),i] <- out$x
  }
  dat[in_res] <- t(M)
  if (remove_tag) remove_tag(dat) else dat
}


CONV_MSG <- c(
  ""
  , "could not allocate enough memory"
  , "divergence detected (set of restrictions may be contradictory)"
  , "maximum number of iterations reached"
)

stopf <- function(fmt,...){
 stop(sprintf(fmt,...), call. = FALSE) 
}

warnf <- function(fmt,...){
  warning(sprintf(fmt,...), call. = FALSE)
}


MISSTAG <- "__MISSINGS__"

#' Tag currently missing elements of a data.frame
#'
#' Attach an attribute that marks which cells are empty (NA).
#'
#'
#' @param dat \code{[data.frame]} to be tagged
#' @param ... Currently not used.
#'
#' @family tagging
#'
#' @return \code{dat}, tagged for missing values.
#' @export
tag_missing <- function(dat, ...){
  attr(dat, MISSTAG) <- is.na(dat)
  dat
}

#' Retrieve tagged cell positions
#' 
#' @param dat \code{[data.frame]}
#' @param ... Currently not used
#'
#' @family tagging
#'
#'
#' @return A \code{logical} matrix, or \code{NULL}
#' @export
tagged_values <- function(dat,...){
  attr(dat,MISSTAG)
}

#' Remove cell position tags
#' 
#' @param dat \code{[data.frame]}
#' @param ... Currently not used
#'
#' @family tagging
#' @return \code{dat} with tag removed
#' 
#' @export
remove_tag <- function(dat,...){
  if (!is.null(attr(dat,MISSTAG))){
    attr(dat,MISSTAG) <- NULL
  }
  dat
}



