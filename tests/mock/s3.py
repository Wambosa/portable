from box import Box

class VoidS3:

  def get_object(self, Bucket='', Key=''):

    def read():
      return b'1234567,http://web.uk,left,2019-01-01T00:01:000Z,87646675465\n8901234,https://web.com,right,2020-01-01T00:00:000Z,99999999999'

    return {
      'Body': Box({
        'read': read
      })
    }


class DiffDelimiterS3:

  def get_object(self, Bucket='', Key=''):

    def read():
      return b'1234567!http://web.uk!left!2019-01-01T00:01:000Z!87646675465\n8901234!https://web.com!right!2020-01-01T00:00:000Z!99999999999'

    return {
      'Body': Box({
        'read': read
      })
    }