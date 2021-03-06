#' Installs & Loads Packages 
#' 
#' Installs a package provided the package is a CRAN package.
#' 
#' @rdname p_install
#' @param package Name of package(s).
#' @param character.only logical.  If \code{TRUE} \code{\dots} is treated a 
#' character string.
#' @param force logical. Should package be installed if it already exists on 
#' local system?
#' @param path The path to the directory that contains the package.  It is 
#' convenient to set \code{download_path} in .Rprofile options to the downloads 
#' directory.
#' @param try.bioconductor If \code{TRUE}, tries to install the package from 
#' Bioconductor if it is not found on CRAN using \pkg{BiocManager}.
#' @param update.bioconductor If \code{TRUE}, tries to update dependencies used
#' by \code{try.bioconductor}. 
#' @param \ldots Additional parameters to pass to \code{install.packages}.
#' @keywords install package
#' @seealso \code{\link[utils]{install.packages}}
#' @export
#' @examples
#' \dontrun{
#' p_install(pacman)
#' }
p_install <- function(package, character.only = FALSE, force = TRUE, 
    path = getOption("download_path"), 
    try.bioconductor = TRUE, update.bioconductor = FALSE, ...){

    if(!character.only){
        package <- as.character(substitute(package))
    }
  
    if (p_exists(package, local = TRUE) && !force){
        
        message("Package is already on your system.")
        return(invisible(TRUE))
      
    } else {

        ## Detect if package ends in zip/tar.gz
        if (grepl("\\.tar\\.gz|\\.zip", package)) {
    
            if (file.exists(package)) {
                tar_path <- package
            } else {
                if (file.exists(file.path(path, package))) {
                    tar_path <- file.path(path, package)
                } else {
                    message("Package not found. Please select file...")
                    tar_path <- file.choose()
                }      
            }
            
            utils::install.packages(tar_path, repos = NULL, type = "source", ...)
          
        } else {
          
            p_set_cranrepo()
    
            if (p_loaded(char = package)) {
                p_unload(char = package)
            }
    
            ## Handling if no package supplied
            if (length(package) == 1 && package == "") {
                package <- NULL 
            } 
    
            ## an environment with a marker indicating if the package installed with 
            ## a not available error
            bioconductor_env <- new.env(hash=FALSE)
            bioconductor_env[['try_bioc_p']] <- FALSE
    
            ## install from CRAN; if not available warning happens record in the
            ## bioconductor environment
            response <- withCallingHandlers(
                utils::install.packages(package, ...),
                warning = function(w){
                    if (grepl("package.*is not available", w$message)) {
                        assign('try_bioc_p', TRUE, envir = bioconductor_env)
                    }
                }
            )
            
    
            ## if the CRAN install failed from not available warning try installing
            ## from bioconductor
            if (try.bioconductor && isTRUE(bioconductor_env[['try_bioc_p']])) {
                try_bioc(package, update.bioconductor)
            }
        }
        
        ## check if package was installed & success notification.
        pack <- ifelse(is.null(package), "Your package", package)
    
        if (pack %in% p_lib() | is.null(package)) {
            
            message(sprintf("\n%s installed", pack))
            return(invisible(TRUE))
            
        } else {
            
            # If unable to install, raise warning and continue
            warning(response)
            return(invisible(FALSE))
            
        }
    
    }  
}


try_bioc <- function(package, update, ...){
    
    if (requireNamespace("BiocManager", quietly = TRUE)){

        ## attempt to install the assumed bioconductor package
        suppressMessages(suppressWarnings(
            eval(parse(
                text=sprintf("BiocManager::install('%s', update = %s)", package, ifelse(update, 'TRUE', 'FALSE'))
            ))
        ))             
        
    } else {
        
        warning('\'BiocManager\' not available.  Could not check Bioconductor.\n\nPlease use `install.packages(\'BiocManager\')` and then retry.', call. = FALSE)
        
    }
    

}

#' @rdname p_install
#' @export
p_get <- p_install
