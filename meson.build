project('com.github.rickybas.date-countdown', ['vala', 'c'],
    version: '0.1.1',
    license: 'GNU',
    meson_version: '>=0.40.1'
)

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
    'as-resources', 'data/css.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

#add_project_arguments(['--enable-debug'], language: 'vala')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

executable(
    'com.github.rickybas.date-countdown',
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/circular-progress-bar.vala',
    'src/DatePicker.vala',
    asresources,
    c_args: c_args,
    link_args: [ '-lm' ],
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite')
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
