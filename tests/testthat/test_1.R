

require(engsoccerdata)
require(dplyr)

# Load data from English Premier League, 2011-12 season.
engsoccerdata::england %>%
  dplyr::filter(Season %in% c(2011),
         tier==c(1)) %>%
  dplyr::mutate(Date = as.Date(Date),
         home = as.character(home),
         visitor= as.character(visitor)) -> england_2011


#########################################

context("Model fitting - Default model")

# fit default model
gm_res <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                    team1 = england_2011$home, team2=england_2011$visitor)



test_that("Fitting default model", {
  expect_equal(class(gm_res), 'goalmodel')
  expect_equal(gm_res$parameters$dispersion, NULL)
  expect_equal(gm_res$parameters$rho, NULL)
  expect_equal(gm_res$parameters$sigma, NULL)
  expect_equal(gm_res$parameters$gamma, NULL)
  expect_equal(any(is.na(gm_res$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res$parameters$defense)), FALSE)
  expect_equal(names(gm_res$parameters$attack), names(gm_res$parameters$defense))
  expect_equal(any(duplicated(names(gm_res$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res$parameters$defense))), FALSE)
  expect_true(gm_res$converged)
})


context("Model fitting - DC model")


gm_res_dc <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                       team1 = england_2011$home, team2=england_2011$visitor,
                       dc=TRUE)

test_that("Fitting Dixon-Coles model", {
  expect_equal(class(gm_res_dc), 'goalmodel')
  expect_equal(gm_res_dc$parameters$dispersion, NULL)
  expect_equal(is.numeric(gm_res_dc$parameters$rho), TRUE)
  expect_equal(gm_res_dc$parameters$gamma, NULL)
  expect_equal(gm_res$parameters$sigma, NULL)
  expect_equal(any(is.na(gm_res_dc$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_dc$parameters$defense)), FALSE)
  expect_equal(names(gm_res_dc$parameters$attack), names(gm_res_dc$parameters$defense))
  expect_equal(any(duplicated(names(gm_res_dc$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res_dc$parameters$defense))), FALSE)
  expect_true(gm_res_dc$converged)

  # Fit DC model on dataset with where there are no low-scoring games
  expect_error(goalmodel(goals1 = england_2011$hgoal+2, goals2 = england_2011$vgoal+2,
                         team1 = england_2011$home, team2=england_2011$visitor,
                         dc=TRUE))
})





context("Model fitting - some fixed parameters")

# Fit the Dixon-Coles model, with most of the parameters fixed to the values in the default model.
my_fixed_params1 <- list(attack = c('Chelsea' = 0.2), defense= c('Fulham' = -0.09, 'Liverpool' = 0.1))

gm_res_fp1 <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                          team1 = england_2011$home, team2=england_2011$visitor,
                          dc=FALSE, fixed_params = my_fixed_params1)


test_that("Fitting default model - some parameters fixed", {
  expect_equal(class(gm_res_fp1), 'goalmodel')
  expect_equal(gm_res_fp1$parameters$dispersion, NULL)
  expect_equal(gm_res_fp1$parameters$gamma, NULL)
  expect_equal(gm_res$parameters$sigma, NULL)
  expect_equal(any(is.na(gm_res_fp1$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_fp1$parameters$defense)), FALSE)
  expect_equal(names(gm_res_fp1$parameters$attack), names(gm_res_fp1$parameters$defense))
  expect_equal(gm_res_fp1$parameters$attack, gm_res_fp1$parameters$attack)
  expect_equal(gm_res_fp1$parameters$defense, gm_res_fp1$parameters$defense)
  expect_equal(any(duplicated(names(gm_res_fp1$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res_fp1$parameters$defense))), FALSE)
  expect_true(gm_res_fp1$converged)
})


context("Model fitting - 2-step estimation")

## Test if two-step estimation works as it should.

# Fit the Dixon-Coles model, with most of the parameters fixed to the values in the default model.
gm_res_dc_2s <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                          team1 = england_2011$home, team2=england_2011$visitor,
                          dc=TRUE, fixed_params = gm_res$parameters)


test_that("Fitting Dixon-Coles model - 2step", {
  expect_equal(class(gm_res_dc_2s), 'goalmodel')
  expect_equal(gm_res_dc_2s$parameters$dispersion, NULL)
  expect_equal(is.numeric(gm_res_dc_2s$parameters$rho), TRUE)
  expect_equal(gm_res$parameters$sigma, NULL)
  expect_equal(gm_res_dc_2s$parameters$gamma, NULL)
  expect_equal(names(gm_res_dc_2s$parameters$attack), names(gm_res_dc_2s$parameters$defense))
  expect_equal(gm_res_dc_2s$parameters$attack, gm_res$parameters$attack)
  expect_equal(gm_res_dc_2s$parameters$defense, gm_res$parameters$defense)
  expect_equal(any(is.na(gm_res_dc_2s$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_dc_2s$parameters$defense)), FALSE)
  expect_equal(gm_res_dc_2s$parameters$rho == gm_res_dc$parameters$rho, FALSE)
  expect_equal(any(duplicated(names(gm_res_dc_2s$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res_dc_2s$parameters$defense))), FALSE)
  expect_true(gm_res_dc_2s$converged)
})



context("Additional covariates")


# Manual hfa
hfa_mat <- matrix(data = 1, ncol=1, nrow=nrow(england_2011))
colnames(hfa_mat) <- 'hfaa'


gm_res_hfax <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                          team1 = england_2011$home, team2=england_2011$visitor,
                          hfa=FALSE, x1=hfa_mat)

test_that("Manual HFA", {
  expect_equal(names(gm_res_hfax$parameters$beta), 'hfaa')
  expect_true(abs(gm_res_hfax$parameters$beta - gm_res$parameters$hfa) < 0.001)
  expect_true(gm_res_hfax$converged)
})



context("Model fitting - Gaussian")

# Fit a Gaussian model.
gm_res_gaussian <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                          team1 = england_2011$home, team2=england_2011$visitor, model='gaussian')

test_that("Fitting Gaussian model", {
  expect_equal(class(gm_res_gaussian), 'goalmodel')
  expect_equal(gm_res_gaussian$parameters$dispersion, NULL)
  expect_equal(is.numeric(gm_res_gaussian$parameters$sigma), TRUE)
  expect_equal(any(is.na(gm_res_gaussian$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_gaussian$parameters$defense)), FALSE)
  expect_equal(gm_res_gaussian$parameters$gamma, NULL)
  expect_equal(names(gm_res_gaussian$parameters$attack), names(gm_res_gaussian$parameters$defense))
  expect_equal(gm_res_gaussian$converged, TRUE)
})


context("CMP functions")

dcmp_vec <- dCMP(x=0:6, lambda=4.4, upsilon = 1.2)
pcmp_vec <- pCMP(x=6, lambda=4.4, upsilon = 1.2)
dp_diff <- sum(dcmp_vec) - pcmp_vec

test_that("CMP", {
  expect_true(all(dcmp_vec >= 0))
  expect_true(all(dcmp_vec <= 1))
  expect_true(pcmp_vec >= 0)
  expect_true(pcmp_vec <= 1)
  expect_true(dp_diff < 0.0001)
})




context("Model fitting - CMP 2 - step")


# fit CMP model
gm_res_cmp <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                    team1 = england_2011$home, team2=england_2011$visitor,
                    fixed_params = gm_res$parameters,
                    model='cmp')


# Estiamte the dispersion with the upsilon.ml function.
expg_default <- predict_expg(gm_res, team1 = england_2011$home, team2=england_2011$visitor)

upsilon_est <- upsilon.ml(x = c(england_2011$hgoal, england_2011$vgoal),
                          parameters=c(expg_default$expg1, expg_default$expg2),
                          param_type = 'mu', method='fast')

upsilon_diff <- abs(gm_res_cmp$parameters$dispersion - upsilon_est)


test_that("Fitting CMP model", {
  expect_equal(class(gm_res_cmp), 'goalmodel')
  expect_true(is.null(gm_res_cmp$parameters$rho))
  expect_true(is.null(gm_res_cmp$parameters$sigma))
  expect_true(is.numeric(gm_res_cmp$parameters$dispersion))
  expect_true(length(gm_res_cmp$parameters$dispersion) == 1)
  expect_equal(any(is.na(gm_res_cmp$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_cmp$parameters$defense)), FALSE)
  expect_equal(names(gm_res_cmp$parameters$attack), names(gm_res_cmp$parameters$defense))
  expect_equal(any(duplicated(names(gm_res_cmp$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res_cmp$parameters$defense))), FALSE)
  expect_true(gm_res_cmp$converged)
  expect_true(upsilon_diff < 0.001)
})

context("Model fitting - Negbin model")

# fit negative binomial model
gm_res_nbin <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                    team1 = england_2011$home, team2=england_2011$visitor, model='negbin')


test_that("Fitting Negative Binomial model", {
  expect_equal(class(gm_res_nbin), 'goalmodel')
  expect_true(is.null(gm_res_nbin$parameters$rho))
  expect_true(is.null(gm_res_nbin$parameters$sigma))
  expect_true(is.numeric(gm_res_nbin$parameters$dispersion))
  expect_true(length(gm_res_nbin$parameters$dispersion) == 1)
  expect_equal(any(is.na(gm_res_nbin$parameters$attack)), FALSE)
  expect_equal(any(is.na(gm_res_nbin$parameters$defense)), FALSE)
  expect_equal(names(gm_res_nbin$parameters$attack), names(gm_res_nbin$parameters$defense))
  expect_equal(any(duplicated(names(gm_res_nbin$parameters$attack))), FALSE)
  expect_equal(any(duplicated(names(gm_res_nbin$parameters$defense))), FALSE)
  expect_true(gm_res_nbin$converged)
})





context("Making predictions")

to_predict1 <- c('Arsenal', 'Manchester United')
to_predict2 <- c('Fulham', 'Chelsea')

pred_expg_default <- predict_expg(gm_res, team1=to_predict1, team2=to_predict2, return_df = FALSE)
pred_expg_dc <- predict_expg(gm_res_dc, team1=to_predict1, team2=to_predict2, return_df = FALSE)

gm_res_dc0 <- gm_res_dc
gm_res_dc0$parameters$rho <- 0

pred_expg_dc0 <- predict_expg(gm_res_dc0, team1=to_predict1, team2=to_predict2, return_df = FALSE)

test_that("Predict expg.", {
  expect_equal(is.numeric(pred_expg_default[[1]]), TRUE)
  expect_equal(is.numeric(pred_expg_dc[[1]]), TRUE)
  expect_equal(is.numeric(pred_expg_dc0[[1]]), TRUE)
  expect_equal(is.numeric(pred_expg_default[[2]]), TRUE)
  expect_equal(is.numeric(pred_expg_dc[[2]]), TRUE)
  expect_equal(is.numeric(pred_expg_dc0[[2]]), TRUE)
})


pred_result_default <- predict_result(gm_res, team1=to_predict1, team2=to_predict2, return_df = FALSE)
pred_result_dc <- predict_result(gm_res_dc, team1=to_predict1, team2=to_predict2, return_df = FALSE)

test_that("Predict result", {
  expect_equal(is.numeric(pred_result_default[[1]]), TRUE)
  expect_equal(is.numeric(pred_result_dc[[1]]), TRUE)
  expect_equal(is.numeric(pred_result_default[[2]]), TRUE)
  expect_equal(is.numeric(pred_result_dc[[2]]), TRUE)
})



pred_goals_default <- predict_goals(gm_res, team1=to_predict1, team2=to_predict2)
pred_goals_dc <- predict_goals(gm_res_dc, team1=to_predict1, team2=to_predict2)

test_that("Predict goals", {
  expect_equal(is.matrix(pred_goals_default[[1]]), TRUE)
  expect_equal(is.matrix(pred_goals_dc[[1]]), TRUE)
  expect_equal(is.matrix(pred_goals_default[[2]]), TRUE)
  expect_equal(is.matrix(pred_goals_dc[[2]]), TRUE)
  expect_equal(any(is.na(pred_goals_default[[1]])), FALSE)
  expect_equal(any(is.na(pred_goals_dc[[1]])), FALSE)
  expect_equal(any(is.na(pred_goals_default[[2]])), FALSE)
  expect_equal(any(is.na(pred_goals_dc[[2]])), FALSE)
})


context("Misc.")

# the weighting function.
my_weights1 <- weights_dc(england_2011$Date, xi=0.0019)
my_weights2 <- weights_dc(england_2011$Date, xi=0.011)
my_weights3 <- weights_dc(england_2011$Date, xi=0.04)

gm_res_w <- goalmodel(goals1 = england_2011$hgoal, goals2 = england_2011$vgoal,
                     team1 = england_2011$home, team2=england_2011$visitor,
                     weights = my_weights1)


test_that("The weighting function", {
  expect_equal(is.numeric(my_weights1), TRUE)
  expect_equal(is.numeric(my_weights2), TRUE)
  expect_equal(is.numeric(my_weights3), TRUE)
  expect_equal(all(my_weights3 >= 0), TRUE)
  expect_equal(all(my_weights2 >= 0), TRUE)
  expect_equal(all(my_weights3 >= 0), TRUE)
  expect_equal(all(unlist(gm_res_w$parameters) == unlist(gm_res$parameters)), FALSE)
  expect_equal(gm_res_w$converged, TRUE)
  expect_error(weights_dc(england_2011$Date, xi=-0.9), 'xi >= 0 is not TRUE')

})



