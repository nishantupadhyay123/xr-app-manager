#!/bin/bash
cwd=`dirname "$(readlink -f "$0")"`
build_container_name="wrl7_rpm_build"
VERSION="0.1.0"
GREEN='\033[0;32m'
NC='\033[0m'

rm -rf ${cwd}/build/*
rm -rf ${cwd}/RPMS/*
rm -f ${VERSION}.tar.gz > /dev/null 2>&1
cd $cwd/build && tar -czvf ${VERSION}.tar.gz ../src/*  


docker rm -f wrl7_rpm_build > /dev/null 2>&1
docker run -itd --rm  --name $build_container_name -v ${cwd}:/root/cwd akshshar/xr-wrl7:latest /root/cwd/build_chown.sh root root
docker rm -f $build_container_name 
docker run -itd --rm  --name $build_container_name -v ${cwd}/app_manager.spec:/usr/src/rpm/SPECS/app_manager.spec -v ${cwd}/build/${VERSION}.tar.gz:/usr/src/rpm/SOURCES/${VERSION}.tar.gz -v ${cwd}/RPMS:/root/RPMS/ -v ${cwd}/build/:/tmp/ akshshar/xr-wrl7:latest /usr/sbin/build_rpm.sh -s /usr/src/rpm/SPECS/app_manager.spec 

echo -ne "\nBuilding ."
while true 
do
  container_running=`docker inspect -f "{{.State.Running}}" $build_container_name 2>/dev/null`

  if [[ $container_running == "true" ]]; then
      echo -ne " . "
      sleep 2
  else
      echo -ne "\n${GREEN}Build process Done!. \nChecking artifacts in ${cwd}/RPMS/x86_64/${NC} \n"
      build_afcts=`ls -l ${cwd}/RPMS/x86_64/*`
      echo -ne "\n${GREEN}${build_afcts}${NC} \n"
      echo -ne "\nIf artifact is not created, check errors in ${cwd}/build/rpmbuild.log\n"
      break
  fi 
done

# Change back the permissions of mounted folders post build
docker run -itd --rm  --name $build_container_name -v ${cwd}:/root/cwd akshshar/xr-wrl7:latest /root/cwd/build_chown.sh `id -u` `id -g`
docker rm -f $build_container_name

echo "# Artifacts during the build process appear in this directory" > ${cwd}/build/README.md
echo "# RPMS built successfully appear here" > ${cwd}/RPMS/README.md
