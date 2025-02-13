from preprocessing import Preprocessing
from inference import SemanticSegmentation
import os


def FSCT(
    parameters,
    preprocess=True,
    segmentation=True,
):
    print("Current point cloud being processed: ", parameters["point_cloud_filename"])
    if parameters["num_cpu_cores"] == 0:
        print("Using default number of CPU cores (all of them).")
        parameters["num_cpu_cores"] = os.cpu_count()
    print("Processing using ", parameters["num_cpu_cores"], "/", os.cpu_count(), " CPU cores.")

    if preprocess:
        preprocessing = Preprocessing(parameters)
        preprocessing.preprocess_point_cloud()
        del preprocessing

    if segmentation:
        sem_seg = SemanticSegmentation(parameters)
        sem_seg.inference()
        del sem_seg