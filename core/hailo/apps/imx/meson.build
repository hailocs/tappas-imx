################################################
# LPR OVERLAY SOURCE
################################################
lpr_overlay_source = '../x86/lpr/lpr_overlay.cpp'

lpr_overlay_lib = shared_library('lpr_overlay',
  lpr_overlay_source,
  cpp_args : hailo_lib_args,
  include_directories: hailo_general_inc,
  dependencies : plugin_deps + [opencv_dep, meta_dep, cv_singleton_dep, image_dep],
  gnu_symbol_visibility : 'default',
  install: install_lpr,
  install_dir: apps_install_dir + '/license_plate_recognition/resources',
)

################################################
# LPR OCR SINK SOURCE
################################################
lpr_ocrsink_source = '../x86/lpr/lpr_ocrsink.cpp'

lpr_ocrsink_lib = shared_library('lpr_ocrsink',
  lpr_ocrsink_source,
  cpp_args : hailo_lib_args,
  include_directories: hailo_general_inc,
  dependencies : plugin_deps + [opencv_dep, meta_dep, cv_singleton_dep, image_dep, tracker_dep],
  gnu_symbol_visibility : 'default',
  install: install_lpr,
  install_dir: apps_install_dir + '/license_plate_recognition/resources',
)

################################################
# VMS FACE ALIGN SOURCE
################################################
face_align_src = '../x86/vms/face_align.cpp'

shared_library('vms_face_align',
  face_align_src,
  cpp_args : hailo_lib_args,
  include_directories: hailo_general_inc,
  dependencies : plugin_deps + [opencv_dep, image_dep],
  gnu_symbol_visibility : 'default',
  install: true,
  install_dir: apps_install_dir + '/libs/vms',
)