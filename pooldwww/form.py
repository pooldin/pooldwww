from wtforms import Form


class BaseForm(Form):

    @property
    def fields(self):
        fields = self._fields or dict()
        return fields.values()

    @property
    def error_list(self):
        errors = map(lambda f: f.errors, self.fields)
        return reduce(lambda l, r: l + r, errors)

    @property
    def error(self):
        errors = self.error_list

        if len(errors) > 0:
            return errors[0]

    def todict(self, *fields):
        return dict([(f.name, f.data)
                      for f in self.fields
                      if f.data is not None and
                         (not fields or f.name in fields)])
