#if defined(__aarch64__) || defined(_M_ARM64)
#define TS_STRIDED_MEMORY_MIN_COUNT 1024
{5168, 4096}, /* f32 negate -1,-1,1,1 */
{6418, 4096}, /* f32 abs -1,-1,1,1 */
{41628, 4096}, /* f32 dot 1,-2,-2,1 */
{41658, 1024}, /* f32 dot 1,-1,-1,1 */
{41668, 1024}, /* f32 dot 1,-1,1,1 */
{41673, 1024}, /* f32 dot 1,-1,2,1 */
{41748, 1024}, /* f32 dot 1,2,2,1 */
{121658, 1024}, /* f32 dot-wide 1,-1,-1,1 */
{121668, 1024}, /* f32 dot-wide 1,-1,1,1 */
{121673, 1024}, /* f32 dot-wide 1,-1,2,1 */
{121748, 4096}, /* f32 dot-wide 1,2,2,1 */
#else
#define TS_STRIDED_MEMORY_MIN_COUNT SIZE_MAX
{UINT32_MAX, SIZE_MAX}
#endif
