# Install required packages (Comment if already installed)
#install.packages(c( "caret", "randomForest", "lidR", "data.table"))

install.packages("remotes")
library(remotes)    # Installing packages from GitHub

# Install specialized GitHub packages
install_github("lucasbielak/lidUrb")      # Urban LiDAR processing
install_github("lucasbielak/ForestClassR") # Forest classification

# Load core libraries
library(lidR)       # LiDAR data processing
library(caret)      # Classification and regression training
library(randomForest) # Random forest modeling
library(data.table) # Efficient data manipulation

# Python integration for geometric feature extraction
library(reticulate)

# Create virtual environment with jakteristics for geometric features
reticulate::install_python("3.12")
virtualenv_create("lidUrb", python = "3.12", packages="jakteristics", pip=TRUE)
use_virtualenv("lidUrb", required = TRUE)

# Load specialized packages
library(lidUrb)       # Urban tree-specific functions
library(ForestClassR) # Forest classification utilities

# Data Loading and Visualization

# Load sample single tree LAS file without ground points
las <- readLAS(system.file("extdata", "tree.las", package = "ForestClassR"))

# Visualize raw point cloud
plot(las)

#filter noise points
las <- classify_noise(las, sor(k = 60, m = 3, quantile = FALSE))

las <- filter_poi(las, Classification != LASNOISE)

plot(las)

# Segmentation

# Perform segmentation using two methods:

segmented <- LW_segmentation_dbscan(las) # 1. DBSCAN (density-based) segmentation

#segmented  <- LW_segmentation_graph(las) # 2. Graph-based segmentation (uncomment to change segmentation method)

# Visualization of segmentation results

# Plot wood probability from DBSCAN segmentation
lidR::plot(segmented, color = "p_wood", legend = TRUE)

# Plot Structure over Density metric
lidR::plot(segmented, color = "SoD", legend = TRUE)

# Classification based on thresholds
wood_leaf_palette <- c("chartreuse4", "cornsilk2") # palette Dark green for leaves, light for wood

# DBSCAN-based wood classification using p_wood threshold
segmented@data[, label := as.numeric(p_wood >= 0.96)]
lidR::plot(segmented, color="label", size=2, pal = wood_leaf_palette)

#plot only wood

wood <- filter_poi(segmented, Classification != label)
plot(wood)

# Machine Learning Classification

# Extract geometric features using jakteristics
las_eigen <- features_jak(segmented, radius = 1)

# Visualize a sample geometric feature from the possible list
# eigenvalue_sum, omnivariance, eigenentropy, anisotropy, planarity, linearity
# PCA1, PCA2, surface_variation, sphericity, verticality, nx, ny, nz

plot(las_eigen, color = 'linearity', legend = TRUE)

# Prepare data for machine learning
df <- extract_jak(las_eigen)
df$class <- as.factor(df$class) # Ensure class is a factor for classification

# Split data into training and testing sets (80/20 split)
set.seed(64) # For reproducibility
trainIndex <- createDataPartition(df$class, p = 0.8, list = FALSE)
trainData <- df[trainIndex, ]
testData <- df[-trainIndex, ]

# Train Random Forest model
model_rf <- randomForest(class ~ ., data = trainData, ntree = 100, importance = TRUE) # Enable importance calculation

# Evaluate model performance
predictions <- predict(model_rf, testData)
conf_matrix <- confusionMatrix(predictions, testData$class)
print(conf_matrix)

# Apply predictions to the entire dataset
predictions_all <- predict(model_rf, df)
predictions_all <- as.numeric(predictions_all)
las_eigen@data$predicted <- predictions_all

# Visualize prediction results and compare with threshold-based classification
plot(las_eigen, color = "predicted", pal = wood_leaf_palette)
plot(las_eigen, color = "label", pal = wood_leaf_palette)

# Model Analysis and Interpretation

# Examine feature importance
feature_importance <- importance(model_rf)
print(feature_importance)

# Create partial dependence plot for a selected feature
feature <- "anisotropy"

partialPlot(model_rf, testData, as.character(feature), 1, # 0 for class leaf 1 for Wood
            plot = TRUE, add = FALSE,
            rug = TRUE, xlab = feature, ylab="Predicted Probability Leaf",
            main=paste("Partial Dependence on", toupper(feature))
)

plot(las_eigen, color = feature, legend = TRUE)

# Add saving capabilities for the model and results
# saveRDS(model_rf, "tree_classification_model.rds")
# write.csv(feature_importance, "feature_importance.csv")
