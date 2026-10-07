library(class)

# 2. Create a tiny training and test set
# knn() requires matrix or data frame inputs for the features
train_data <- matrix(c(1, 1,   2, 2,   10, 10,   11, 11), ncol = 2, byrow = TRUE)
test_data  <- matrix(c(1.5, 1.5,   10.5, 10.5), ncol = 2, byrow = TRUE)

# 3. Define the true classes for the training data
train_labels <- as.factor(c("Low", "Low", "High", "High"))

# 4. Run KNN (k=1) to classify the test data
# This triggers the compiled C code underneath
predictions <- knn(train = train_data, test = test_data, cl = train_labels, k = 1)

# 5. Output the results to verify it works
print("Class package check passed!")
print(predictions)