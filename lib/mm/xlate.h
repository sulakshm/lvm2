/*
 * Copyright (C) 2001-2004 Sistina Software, Inc. All rights reserved.  
 * Copyright (C) 2004-2005 Red Hat, Inc. All rights reserved.
 *
 * This file is part of LVM2.
 *
 * This copyrighted material is made available to anyone wishing to use,
 * modify, copy, or redistribute it subject to the terms and conditions
 * of the GNU Lesser General Public License v.2.1.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef _LVM_XLATE_H
#define _LVM_XLATE_H

#ifdef __linux__
#  include <endian.h>
#  include <byteswap.h>
#else
#  include <machine/endian.h>
#  define bswap_16(x) (((x) & 0x00ffU) << 8 | \
		       ((x) & 0xff00U) >> 8)
#  define bswap_32(x) (((x) & 0x000000ffU) << 24 | \
		       ((x) & 0xff000000U) >> 24 | \
		       ((x) & 0x0000ff00U) << 8  | \
		       ((x) & 0x00ff0000U) >> 8)
#  define bswap_64(x) (((x) & 0x00000000000000ffULL) << 56 | \
		       ((x) & 0xff00000000000000ULL) >> 56 | \
		       ((x) & 0x000000000000ff00ULL) << 40 | \
		       ((x) & 0x00ff000000000000ULL) >> 40 | \
		       ((x) & 0x0000000000ff0000ULL) << 24 | \
		       ((x) & 0x0000ff0000000000ULL) >> 24 | \
		       ((x) & 0x00000000ff000000ULL) << 8 | \
		       ((x) & 0x000000ff00000000ULL) >> 8)
#endif

#if BYTE_ORDER == LITTLE_ENDIAN
/* New clearer variants. */
#define le16_to_cpu(x) (x)
#define le32_to_cpu(x) (x)
#define le64_to_cpu(x) (x)
#define cpu_to_le16(x) (x)
#define cpu_to_le32(x) (x)
#define cpu_to_le64(x) (x)
#define be16_to_cpu(x) bswap_16(x)
#define be32_to_cpu(x) bswap_32(x)
#define be64_to_cpu(x) bswap_64(x)
#define cpu_to_be16(x) bswap_16(x)
#define cpu_to_be32(x) bswap_32(x)
#define cpu_to_be64(x) bswap_64(x)
/* Old alternative variants. */
#define xlate16(x) (x)
#define xlate32(x) (x)
#define xlate64(x) (x)
#define xlate16_be(x) bswap_16(x)
#define xlate32_be(x) bswap_32(x)
#define xlate64_be(x) bswap_64(x)

#elif BYTE_ORDER == BIG_ENDIAN
/* New clearer variants. */
#define le16_to_cpu(x) bswap_16(x)
#define le32_to_cpu(x) bswap_32(x)
#define le64_to_cpu(x) bswap_64(x)
#define cpu_to_le16(x) bswap_16(x)
#define cpu_to_le32(x) bswap_32(x)
#define cpu_to_le64(x) bswap_64(x)
#define be16_to_cpu(x) (x)
#define be32_to_cpu(x) (x)
#define be64_to_cpu(x) (x)
#define cpu_to_be16(x) (x)
#define cpu_to_be32(x) (x)
#define cpu_to_be64(x) (x)
/* Old alternative variants. */
#define xlate16(x) bswap_16(x)
#define xlate32(x) bswap_32(x)
#define xlate64(x) bswap_64(x)
#define xlate16_be(x) (x)
#define xlate32_be(x) (x)
#define xlate64_be(x) (x)

#else
#include <asm/byteorder.h>
/* New clearer variants. */
#define le16_to_cpu(x) __le16_to_cpu(x)
#define le32_to_cpu(x) __le32_to_cpu(x)
#define le64_to_cpu(x) __le64_to_cpu(x)
#define cpu_to_le16(x) __cpu_to_le16(x)
#define cpu_to_le32(x) __cpu_to_le32(x)
#define cpu_to_le64(x) __cpu_to_le64(x)
#define be16_to_cpu(x) __be16_to_cpu(x)
#define be32_to_cpu(x) __be32_to_cpu(x)
#define be64_to_cpu(x) __be64_to_cpu(x)
#define cpu_to_be16(x) __cpu_to_be16(x)
#define cpu_to_be32(x) __cpu_to_be32(x)
#define cpu_to_be64(x) __cpu_to_be64(x)
/* Old alternative variants. */
#define xlate16(x) __cpu_to_le16(x)
#define xlate32(x) __cpu_to_le32(x)
#define xlate64(x) __cpu_to_le64(x)
#define xlate16_be(x) __cpu_to_be16(x)
#define xlate32_be(x) __cpu_to_be32(x)
#define xlate64_be(x) __cpu_to_be64(x)
#endif

#endif
