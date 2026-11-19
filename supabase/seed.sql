-- =====================================================================
-- Seed data. IMPORTANT: clinical content below must be reviewed and
-- signed off by a pediatrician before any real pilot.
-- =====================================================================

-- Illustrative schedule based on India's UIP + IAP recommendations.
insert into public.vaccine_templates (name, protects_against, age_label, offset_days) values
  ('BCG',                    'Tuberculosis',                        'Birth',     0),
  ('OPV 0',                  'Polio',                               'Birth',     0),
  ('Hepatitis B 1',          'Hepatitis B',                         'Birth',     0),
  ('DTwP/DTaP 1',            'Diphtheria, Tetanus, Pertussis',      '6 weeks',   42),
  ('IPV 1',                  'Polio',                               '6 weeks',   42),
  ('Hib 1',                  'Haemophilus influenzae type b',       '6 weeks',   42),
  ('Hepatitis B 2',          'Hepatitis B',                         '6 weeks',   42),
  ('Rotavirus 1',            'Rotavirus diarrhoea',                 '6 weeks',   42),
  ('PCV 1',                  'Pneumococcal disease',                '6 weeks',   42),
  ('DTwP/DTaP 2',            'Diphtheria, Tetanus, Pertussis',      '10 weeks',  70),
  ('IPV 2',                  'Polio',                               '10 weeks',  70),
  ('Hib 2',                  'Haemophilus influenzae type b',       '10 weeks',  70),
  ('Rotavirus 2',            'Rotavirus diarrhoea',                 '10 weeks',  70),
  ('PCV 2',                  'Pneumococcal disease',                '10 weeks',  70),
  ('DTwP/DTaP 3',            'Diphtheria, Tetanus, Pertussis',      '14 weeks',  98),
  ('IPV 3',                  'Polio',                               '14 weeks',  98),
  ('Hib 3',                  'Haemophilus influenzae type b',       '14 weeks',  98),
  ('Rotavirus 3',            'Rotavirus diarrhoea',                 '14 weeks',  98),
  ('PCV 3',                  'Pneumococcal disease',                '14 weeks',  98),
  ('Hepatitis B 3',          'Hepatitis B',                         '6 months',  183),
  ('Influenza 1',            'Seasonal influenza',                  '6 months',  183),
  ('MMR 1',                  'Measles, Mumps, Rubella',             '9 months',  274),
  ('Typhoid conjugate',      'Typhoid fever',                       '9 months',  274),
  ('Hepatitis A 1',          'Hepatitis A',                         '12 months', 365),
  ('MMR 2',                  'Measles, Mumps, Rubella',             '15 months', 456),
  ('Varicella 1',            'Chickenpox',                          '15 months', 456),
  ('PCV booster',            'Pneumococcal disease',                '15 months', 456),
  ('DTwP/DTaP booster 1',    'Diphtheria, Tetanus, Pertussis',      '18 months', 548),
  ('IPV booster',            'Polio',                               '18 months', 548),
  ('Hib booster',            'Haemophilus influenzae type b',       '18 months', 548),
  ('Hepatitis A 2',          'Hepatitis A',                         '18 months', 548),
  ('DTwP/DTaP booster 2',    'Diphtheria, Tetanus, Pertussis',      '4-6 years', 1643),
  ('OPV booster',            'Polio',                               '4-6 years', 1643),
  ('Varicella 2',            'Chickenpox',                          '4-6 years', 1643);

-- Default weight-based formulary (clinic_id NULL = global).
-- reviewed = false  ->  the app shows a "verify" warning to the doctor.
insert into public.drug_formulary
  (name, form, strength_mg, strength_ml, mg_per_kg_per_dose, doses_per_day,
   max_mg_per_kg_per_day, max_single_dose_mg, min_age_months, default_duration_days, instructions)
values
  ('Paracetamol', 'Syrup 125 mg/5 mL', 125, 5, 15, 4, 60, 500, 3, 3,
   'Give every 6 hours only if fever or pain. Do not exceed 4 doses in 24 hours.'),
  ('Ibuprofen',   'Syrup 100 mg/5 mL', 100, 5, 10, 3, 30, 400, 6, 3,
   'Give after food, every 8 hours only if needed.'),
  ('Amoxicillin', 'Syrup 250 mg/5 mL', 250, 5, 15, 3, 90, 500, 1, 5,
   'Complete the full course even if the child feels better.');
