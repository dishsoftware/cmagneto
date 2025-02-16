// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
//
#ifndef ENOWSW_CONTACTS_HPP
#define ENOWSW_CONTACTS_HPP


#if defined(CONTACTS_EXPORTS) || defined(contacts_EXPORTS)
#   if defined(_WIN32)
#       if defined(__GNUC__)
#           define CONTACTS_EXPORT __attribute__((visibility("default")))
#       elif defined(_MSC_VER)
#           define CONTACTS_EXPORT __declspec(dllexport)
#       else
#           define CONTACTS_EXPORT
#       endif
#   else // Not Windows.
#       if defined(__GNUC__)
#           define CONTACTS_EXPORT __attribute__((visibility("default")))
#       else
#           define CONTACTS_EXPORT
#       endif
#   endif
#else // Import case.
#   if defined(_WIN32)
#       if defined(__GNUC__)
#           define CONTACTS_EXPORT
#       elif defined(_MSC_VER)
#           define CONTACTS_EXPORT __declspec(dllimport)
#       else
#           define CONTACTS_EXPORT
#       endif
#   else // Not Windows.
#       if defined(__GNUC__)
#           define CONTACTS_EXPORT
#       else
#           define CONTACTS_EXPORT
#       endif
#   endif
#endif


#if defined(_MSC_VER)
#   pragma warning ( disable: 4251 )
#endif


#if defined(_DEBUG) || defined(DEBUG)
#   include <assert.h>
#   define CONTACTS_VERIFY(x) assert( x );
#   define CONTACTS_ASSERT(x) assert( x );
#else
#   define CONTACTS_VERIFY(x) x
#   define CONTACTS_ASSERT(x)
#endif

#endif  // ENOWSW_CONTACTS_HPP