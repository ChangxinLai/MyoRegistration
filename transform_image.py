import cv2
import math
import scipy.ndimage
import numpy as np
import pydicom

def transform_mask(mask, matrix, output_shape):
    """
    :param mask: the mask image (512*512)
    :param matrix: file name of matrix (.txt)
    :param output_shape: shape of output image (cols, rows)
    :return: mask after transformation
    """

    transform = np.loadtxt(matrix ,dtype=np.float32)
    scale = math.sqrt(transform[0,0]**2 + transform[0,1]**2)
    transform[0,0] = scale
    transform[1,1] = scale
    transform[1,0] = 0
    transform[0,1] = 0
    invT = np.linalg.inv(transform)

    dst = scipy.ndimage.interpolation.affine_transform(mask,invT,output_shape=output_shape,mode='nearest')

    return dst

def get_pixel_spacing(dicom):
    """
    :param dicom: file name of dicom
    :return: pixel_spacing
    """
    dcm = pydicom.dcmread(dicom)
    return dcm.PixelSpacing


mask = cv2.imread('E:\\JHU\\Data\\data_small\\P001\\1_myomask.tif')[:,:,0]
matrix = "E:\\JHU\\Data\\data_original\\P001_JHU011\\Transmatrix\\T-1.txt"
dcm = pydicom.dcmread("E:\\JHU\\Data\\data_original\\P001_JHU011\\DICOM\\0001.dcm")

mask_new = transform_mask(mask, matrix, dcm.pixel_array.shape)

cv2.namedWindow("Image")
cv2.imshow("Image",mask_new)
cv2.waitKey(0)
