file(WRITE "${FILE_PATH}" "Built test targets:\n")
foreach(_target IN LISTS TEST_TARGETS)
    file(APPEND "${FILE_PATH}" "${_target}\n")
endforeach()

string(TIMESTAMP _targetCompilationFinishTime "%Y-%m-%d %H:%M:%S" UTC)
file(APPEND "${FILE_PATH}" "Compilation of test targets finished at: ${_targetCompilationFinishTime} UTC\n")