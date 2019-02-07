# Soft-brightness - Control the display's brightness via an alpha channel.
# Copyright (C) 2019 Philippe Troin <phil@fifi.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Boilerplate
project('soft-brightness',
	 version: '3',
	 meson_version: '>= 0.40.0',
	 license: 'GPL3' )

gettext_domain = meson.project_name()

gnome = import('gnome')
i18n  = import('i18n')

extension_uuid_suffix = '@fifi.org'

extension_lib_convenience = files('gse-lib/lib/convenience.js')

# Extension settings
m4_include([../meson.build.gse-lib])m4_dnl

# Boilerplate
run_home = run_command('sh', '-c', 'echo $HOME')
if run_home.returncode() != 0
  error('HOME not found, exit=@0@'.format(run_home.returncode()))
endif
home     = run_home.stdout().strip()

extension_uuid		       = meson.project_name() + extension_uuid_suffix
extension_target_dir	       = home + '/.local/share/gnome-shell/extensions/' + extension_uuid
extension_target_dir_schemas   = join_paths(extension_target_dir, 'schemas')
extension_target_locale_dir    = join_paths(extension_target_dir, 'locale')
extension_target_dir_dbus_intf = join_paths(extension_target_dir, 'dbus-interfaces')

meson_extra_scripts            = 'gse-lib/meson-scripts'

extension_metadata_conf = configuration_data()
git_rev_cmd = run_command('git', 'rev-parse', 'HEAD')
if git_rev_cmd.returncode() != 0
  warning('git rev-parse exit=@0@'.format(git_rev_cmd.returncode()))
  extension_metadata_conf.set('VCS_TAG', 'unknown')
else
  extension_metadata_conf.set('VCS_TAG', git_rev_cmd.stdout().strip())
endif
extension_metadata_conf.set('uuid', extension_uuid)
extension_metadata_conf.set('version', meson.project_version())
extension_metadata_conf.set('gettext_domain', gettext_domain)

extension_data += configure_file(input:         'src/metadata.json.in',
				 output:        'metadata.json',
				 configuration: extension_metadata_conf)

# This should work but doesn't:
#extension_metadata = vcs_tag(command:  ['git', 'rev-parse', 'HEAD'],
#			     input:    files('metadata.json.in'),
#			     output:   'metadata.json',
#			     fallback: 'unknown')
#extension_data += extension_metadata

custom_target('gschemas.compiled',
	      build_by_default: true,
	      command:          ['sh', '-c', 'glib-compile-schemas --targetdir . $(dirname @INPUT0@)'],
	      input:            extension_schemas,
	      output:           'gschemas.compiled',
	      install:          true,
	      install_dir:      extension_target_dir_schemas)
install_data(extension_schemas,
	     install_dir: extension_target_dir_schemas)

install_data(extension_sources + extension_data + extension_libs,
	     install_dir: extension_target_dir)

install_data(extension_dbus_interfaces,
	     install_dir: extension_target_dir_dbus_intf)

custom_target('extension',
	      build_by_default: false,
	      install: false,
	      command: [files(join_paths(meson_extra_scripts, 'make-extension')), extension_target_dir, '@OUTDIR@', '@OUTPUT@'],
	      output:  'extension.zip')

subdir('po')
