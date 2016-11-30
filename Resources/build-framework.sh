TARGET=BRFullTextSearch
ACTION="clean build"
LIB=libBRFullTextSearch.a
PRODUCT=BRFullTextSearch
SDKS="iphoneos iphonesimulator"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/Framework"
HEADERS_DIR="${OUTPUT_DIR}/Headers"
RESOURCE_DIR="${OUTPUT_DIR}/Resources"

# Start clean by removing output dir
rm -rf "${HEADERS_DIR}"
mkdir -p "${HEADERS_DIR}"

# Copy source headers into flat Headers directory
rsync -a --no-l -L "${PROJECT_DIR}/Pods/Headers/Public/BRCLucene/" "${HEADERS_DIR}/"
rsync -a --include '**/*.h' --exclude '*' "${PROJECT_DIR}/${PRODUCT}/" "${HEADERS_DIR}/"
rsync -a --include '*.lproj/' --include '*.lproj/*' --exclude '*' "${PROJECT_DIR}/${PRODUCT}/" "${RESOURCE_DIR}/"

echo "Output to: ${OUTPUT_DIR}"

# change to "Release Debug" to build both
CONFIGURATIONS="Release"
for CONFIG in ${CONFIGURATIONS}; do
    FRAMEWORK_DIR="${OUTPUT_DIR}/${CONFIG}/${PRODUCT}.framework"

    echo "Building $CONFIG build to ${FRAMEWORK_DIR}"
    rm -rf "${FRAMEWORK_DIR}"

    DEVICE_DIR="${BUILD_DIR}/${CONFIG}-iphoneos"
    SIMULATOR_DIR="${BUILD_DIR}/${CONFIG}-iphonesimulator"
    UNIVERSAL_DIR="${BUILD_DIR}/${CONFIG}-universal"

    cd ${PROJECT_DIR}
	for SDK in ${SDKS}; do
   		echo "Building ${CONFIG} ${SDK}..."
		xcodebuild -workspace BRFullTextSearch.xcworkspace -scheme BRFullTextSearch -configuration ${CONFIG} -sdk ${SDK} ${ACTION} \
			RUN_CLANG_STATIC_ANALYZER=NO OBJROOT="${BUILD_DIR}" SYMROOT="${BUILD_DIR}" >/dev/null
	done

    rm -rf "${UNIVERSAL_DIR}"
    mkdir "${UNIVERSAL_DIR}"

   	echo "Creating universal framework to ${UNIVERSAL_DIR}/${PRODUCT}..."
    lipo -create -output "${UNIVERSAL_DIR}/${PRODUCT}" "${DEVICE_DIR}/${LIB}" "${SIMULATOR_DIR}/${LIB}"

    mkdir -p "${FRAMEWORK_DIR}/Versions/A"

    cd "${FRAMEWORK_DIR}/Versions"
    ln -sf A Current

    cp -r "${HEADERS_DIR}" "${FRAMEWORK_DIR}/Versions/Current/"
    cp -r "${RESOURCE_DIR}" "${FRAMEWORK_DIR}/Versions/Current/"
    cp "${UNIVERSAL_DIR}/${PRODUCT}" "${FRAMEWORK_DIR}/Versions/Current"

    cd "${FRAMEWORK_DIR}"
    ln -sf "Versions/Current/${PRODUCT}" "${PRODUCT}"
    ln -sf Versions/Current/Headers Headers
    ln -sf Versions/Current/Resources Resources
done

echo "Frameworks built to ${OUTPUT_DIR}"
