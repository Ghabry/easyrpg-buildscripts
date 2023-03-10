#!/bin/sh

export BUILD_SHARED=1

./../linux-static/1_download_library.sh \
	&& ./../linux-static/2_build_toolchain.sh \
	&& ./../linux-static/3_cleanup.sh
