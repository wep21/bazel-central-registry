// Stand-in for the header that CMake's generate_export_header() writes in
// upstream's build. This module builds OGRE for Linux and macOS with default
// symbol visibility, so the export macros expand to nothing.
#ifndef __OgreGLSupportPrerequisites_H__
#define __OgreGLSupportPrerequisites_H__
#define _OgreGLExport
#endif
