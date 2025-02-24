# install.packages(c("remotes","caret","randomforest","lidR","data.table"))

library(remotes)
install_github("lucasbielak/ForestClassR")
library(lidR)
library(ForestClassR)
library(caret)
library(randomForest)
library(data.table)

setup_env()

las <- readLAS(system.file("extdata", "sample_1tree.las", package = "ForestClassR"))

las_class <- classify_noise(las, sor(k = 50, m = 3, quantile = FALSE))

las_denoise <- filter_poi(las_class, Classification != LASNOISE)

segmented <- run_fsct(las_denoise)

custom_colors <- c("#5C4033", "#228B22","#a14023","#8B4513")
plot(segmented, color = "label", pal = custom_colors,bg = "darkgray")

# Calculate features

las_eigen <- features_jak(segmented, radius = 1.0)

plot(las_eigen,color = 'planarity')

# Train RF model

df <- extract_jak(las_eigen)

df$class <- as.factor(df$class)

set.seed(64)
trainIndex <- createDataPartition(df$class, p = 0.8, list = FALSE)
trainData <- df[trainIndex, ]
testData  <- df[-trainIndex, ]

model_rf <- randomForest(class ~ ., data = trainData, ntree = 100)

predictions <- predict(model_rf, testData)

conf_matrix <- confusionMatrix(predictions, testData$class)
print(conf_matrix)

predictions_all <- predict(model_rf, df)

predictions_all <- as.numeric(predictions_all)

las_eigen@data$predicted <- predictions_all

plot(las_eigen, color = "predicted", pal = custom_colors, bg = "darkgray")
plot(las_eigen, color = "label", pal = custom_colors, bg = "darkgray")

########
feature_importance <- importance(model_rf)
print(feature_importance)

# model, var, class (0 = ground, 1 = leaf, 2 = CWD, 3 = wood)
partialPlot(model_rf, trainData, 'planarity', 1,
            plot = TRUE, add= False,
            rug = TRUE, xlab='vst', ylab="",
            main=paste("Partial Dependence on", 'Planarity')
            )

### Test in other LAS

las_t <- readLAS(system.file("extdata", "sample.las", package = "ForestClassR"))
print(lidR::density(las_t))

las_t <- classify_noise(las_t, sor(k = 50, m = 3, quantile = FALSE))
las_t <- filter_poi(las_t, Classification != LASNOISE)

las_t <- decimate_points(las_t, algorithm = random(5000))

las_eigen2 <- features_jak(las_t, radius = 1.0)

df2 <- extract_jak(las_eigen2)

predictions_all2 <- predict(model_rf, df2)

predictions_all2 <- as.numeric(predictions_all2)

las_eigen2@data$predicted <- predictions_all2

plot(las_eigen2, color = "predicted", pal = custom_colors, bg = "darkgray")
