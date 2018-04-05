curr_dir=`pwd`
./makeFlatSols.sh
cd ../compile
./generate_contract_java_wrapper.sh
cd $curr_dir
