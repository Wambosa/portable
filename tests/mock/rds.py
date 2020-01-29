from box import Box

class Rds:

  def executemany(self, _sql, jobs):
    return Box({'lastrowid': 99, 'rowcount': len(jobs)})
