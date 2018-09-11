import cv2
import math
import scipy.ndimage
import numpy as np
import pydicom
import os
import glob

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


root_dir = os.path.abspath('.')
mask_folder = 'data_mask'
data_folder = 'data_new'

for p in range(1,2):
    patient_name = 'P'+"%03d" % p

    mask_dir = glob.glob(os.path.join(root_dir, mask_folder) + '/%s' % patient_name)[0]
    data_dir = glob.glob(os.path.join(root_dir, data_folder) + '/%s_*' % patient_name)[0]

    mask_image_paths = sorted(
        glob.glob(mask_dir + '/*[0-9]_myomask.tif'),
        key=lambda n: int(str.replace(str.replace(n, mask_dir + '/', ''), '_myomask.tif', ''))
    )

    mask_images = [cv2.imread(m, 0) for m in mask_image_paths]

    '''
    matrix_path = sorted(
        glob.glob(os.path.join(data_dir, 'Transmatrix') + '/T-*[0-9].txt'),
        key=lambda n: int(str.replace(str.replace(n, os.path.join(data_dir, 'Transmatrix') + '/T-', ''), '.txt', ''))
    )

    dcm_paths = sorted(
        glob.glob(os.path.join(data_dir, 'DICOM') + '/*[0-9].dcm'),
        key=lambda n: int(str.replace(str.replace(n, os.path.join(data_dir, 'DICOM') + '/', ''), '.dcm', ''))
    )

    dcm_images = [pydicom.dcmread(n) for n in dcm_paths]
    '''

    for i in range(len(mask_image_paths)):
        image_no = int(str.replace(str.replace(mask_image_paths[i], mask_dir + '/', ''), '_myomask.tif', ''))
        matrix = os.path.join(data_dir, 'Transmatrix') + '/T-%s.txt' % image_no
        dcm_path = os.path.join(data_dir, 'DICOM') + '/%04d.dcm' % image_no
        dcm = pydicom.dcmread(dcm_path)
        mask_new = transform_mask(mask_images[i], matrix, dcm.pixel_array.shape)
        cv2.imwrite(os.path.join(data_dir,'myomask')+'/%s_myomask_recovered.tif' % image_no, mask_new)





