'''
A example database abstraction layer for brevity elsewhere in the codebase.
'''

import pymysql.cursors


class Aurora:
  '''
  Is meant to be used with aws Aurora, however, can operate in general for any mysql connection.
  '''

  def __init__(self, host='localhost', port=3306, db='example', user='root', password=''):
    self.host = host
    self.port = port
    self.db = db
    self.user = user
    self.password = password
    self.conn = None

  def __enter__(self):
    self.conn = pymysql.connect(
      host=self.host,
      port=self.port,
      db=self.db,
      user=self.user,
      password=self.password,
      charset='utf8',
      cursorclass=pymysql.cursors.DictCursor
    )
    return self

  def __exit__(self, _type, _value, _traceback):
    return self.conn.close()

  def executemany(self, sql, record_list):
    '''
    Run a complex write query.

    Example:
      insert into `table` (`col_1`, `col_2`) values (%s, %s);

    Params:
      sql (str): parameterized sql query.
      record_list (list of tuples): this is a list with an ordinal tuple representing every record.
      (the order of the items in the tuple is important!)

    Returns:
      pymysql.cursor: the connection cursor used to make the query
      (common usecase is cursor.rowcount)
    '''
    with self.conn.cursor() as cursor:
      cursor.execute('SET NAMES utf8;')
      cursor.execute('SET CHARACTER SET utf8;')
      cursor.execute('SET character_set_connection=utf8;')
      print(sql)
      print(record_list)
      cursor.executemany(sql, record_list)
    self.conn.commit()
    return cursor

  def select(self, sql, itersize=100):
    '''
    Read from database in configured chunks (itersize).

    Example:
      select * from mytable

    Params:
      sql (str): sql query.
      itersize (int): the number of records to return per yield.

    Yields:
      tuple(dict): a number of dictionary objects representing the source table.
    '''
    with self.conn.cursor() as cursor:
      cursor.itersize = itersize
      cursor.execute(sql)

      for records in cursor:
        yield records
