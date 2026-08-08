/*
 * UltSQL C/C++ FFI Header File
 * SQLite-Compatible C API Interface for libultsql
 */
#ifndef ULTSQL_H
#define ULTSQL_H

#ifdef __cplusplus
extern "C" {
#endif

typedef int ultsql_db_t;
typedef int ultsql_res_t;

ultsql_db_t ultsql_open(const char* db_path);
ultsql_res_t ultsql_exec(ultsql_db_t db, const char* sql);
int ultsql_step(ultsql_res_t res);
const char* ultsql_column_text(ultsql_res_t res, int col_index);
int ultsql_column_int(ultsql_res_t res, int col_index);
double ultsql_column_double(ultsql_res_t res, int col_index);
void ultsql_close(ultsql_db_t db);

#ifdef __cplusplus
}
#endif

#endif // ULTSQL_H
