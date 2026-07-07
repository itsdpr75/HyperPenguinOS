cmake_minimum_required(VERSION 3.16)
project(kcm_rollback LANGUAGES CXX)

set(QT_MIN_VERSION "6.5.0")
set(KF_MIN_VERSION "6.0.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Qml
    Quick
    Widgets
)

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    KCMUtils
    Kirigami2
    I18n
    CoreAddons
)

kcoreaddons_desktop_to_json(kcm_rollback_json_data metadata.desktop)

kcmutils_add_plugin(kcm_rollback
    SOURCES
        src/kcm_rollback.cpp
        src/kcm_rollback.h
    QML_DIRS
        ui/
    KCFG_MODULES
    LINK_LIBRARIES
        Qt6::Core
        Qt6::Qml
        Qt6::Quick
        Qt6::Widgets
        KF6::KCMUtils
        KF6::Kirigami2
        KF6::I18n
        KF6::CoreAddons
    INSTALL_KSERVICE
)

install(TARGETS kcm_rollback
    DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/kcm
)

install(FILES
    metadata.desktop
    DESTINATION ${KDE_INSTALL_KSERVICESDIR}
)

install(FILES
    ${CMAKE_SOURCE_DIR}/src/rollback_backend.cpp
    DESTINATION ${KDE_INSTALL_LIBDIR}/kcm_rollback
)
