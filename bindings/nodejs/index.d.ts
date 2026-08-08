declare module 'ultsql' {
  export interface UltSQLClientOptions {
    host?: string;
    port?: number;
  }

  export class UltSQLClient {
    constructor(options?: UltSQLClientOptions);
    query<T = any>(tableName: string): Promise<{ table: string; columns: string[]; count: number; rows: T[] }>;
    insert(tableName: string, recordObject: Record<string, any>): Promise<{ message: string }>;
    truncate(tableName: string): Promise<{ message: string }>;
  }
}
