from odoo import models, fields

#estructura de datos de un nuevo modulo
class GradesCourse(models.Model):
    _name = 'grades.course'
    _description = 'Course Information'

    name = fields.Char(string='Course Name', required=True)
    student_qty = fields.Integer(string='Student Quantity')
    grades_average = fields.Float(string='Grades Average')
    description = fields.Text(string='Description')
    is_active = fields.Boolean(string='Is Active', default=True)
    course_start = fields.Date(string='Course Start')
    course_end = fields.Date(string='Course End')
    last_evaluation_date = fields.Datetime(string='Last Evaluation Date')
    course_image = fields.Binary(string='Course Image')
    course_shift = fields.Selection(
        [('day', 'Day'), ('night', 'Night')],
        string='Course Shift',
        default='day'
    )