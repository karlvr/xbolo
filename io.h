/*
 *  io.h
 *  XBolo
 *
 *  Created by Robert Chrzanowski.
 *  Copyright 2004 Robert Chrzanowski. All rights reserved.
 *
 */

#ifndef __IO__
#define __IO__

#include <unistd.h>
#include <sys/socket.h>

/*!
 * Reads \c nbytes of file descriptor \c d into <code>buf</code>.  Returns \c nbytes
 * on success and \c -1 on failure and sets <code>errno</code>.
 */
ssize_t readblock(int d, void *buf, size_t nbytes);

/*!
 * Writes \c nbytes of \c buf to file descriptor <code>d</code>.  Returns \c nbytes
 * on success and \c -1 on failure and sets <code>errno</code>.
 */
ssize_t writeblock(int d, const void *buf, size_t nbytes);

/*!
 * Writes the string \c str to the file descriptor <code>d</code>.  Returns \c 0
 * on success and \c -1 on failure and sets <code>errno</code>.
 */
ssize_t writestr(int d, const char *str);

/*!
 * Sends \c len bytes of \c msg to socket <code>s</code>.  Returns \c 0
 * on success, or \c -1 on failure and sets <code>errno</code>.
 */
int sendblock(int s, const void *msg, size_t len);

/*!
 * Sends the characters in \c str including the terminating \c NUL
 * character.  Returns \c 0 on success, or \c -1 on failure and sets <code>errno</code>.
 */
int sendstr(int s, const char *str);

/*
 * Sends \c len bytes of \c msg to socket <code>s</code>.  Returns \c 0
 * on success, or \c -1 on failure and sets <code>errno</code>.  Changes \c len to the
 * number of bytes sent regardless of success or failure.
 */
//int sendblockto(int s, const void *msg, size_t *len, int flags, const struct sockaddr *to, int tolen);

/*!
 * Attempts to read \c len bytes to \c buf from socket <code>s</code>.  Returns number of bytes
 * received on success, or \c -1 on failure and sets <code>errno</code>.
 */
ssize_t recvblock(int s, void *buf, size_t len);

/*!
 * Writes \c len bytes to \c buf from socket \c s but does not remove
 * them from the buffer.  Returns number of bytes received on success, or \c -1
 * on failure and sets <code>errno</code>.
 */
ssize_t recvblockpeek(int s, void *buf, size_t len);

/*!
 * Reads socket \c s until a terminating NUL character is found and
 * allocates a string which is what \c str is set to.  Returns number of bytes
 * read including terminating \c NUL character on success, or \c -1 on failure and
 * sets <code>errno</code>.  Caller must \c free() \c str when it no longer needs it.
 */
ssize_t recvstr(int s, char **str);

/*!
 * Receives \c nbytes of socket \c s into <code>buf</code>.  Returns \c 0
 * on success and \c -1 on failure and sets <code>errno</code>.  Changes \c nbytes to the
 * number of bytes received regardless of success or failure.
 */
ssize_t recvblockfrom(int s, void *buf, size_t *len, int flags, struct sockaddr *from, socklen_t *fromlen);

int closesock(int *sock);

#endif  /* __IO__ */
