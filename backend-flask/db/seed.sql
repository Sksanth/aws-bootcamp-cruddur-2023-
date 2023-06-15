-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Sasi', 'sasi' ,'sasi@gmail.com','MOCK'),
  ('sasi thv', 'thv','sasithv@sk.com' ,'MOCK'),
  ('sasi tg', 'sasitg' ,'tgsasi@cloudproject.com' ,'MOCK'),
  ('Londo Mollari','londo' ,'lmollari@centari.com' ,'MOCK');
  

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'sasi' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  ),
  (
    (SELECT uuid from public.users WHERE users.handle = 'thv' LIMIT 1),
    'I am the other!',
    current_timestamp + interval '10 day'
  );