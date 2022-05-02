(*
  (C)2021-2022 Magno Lima - www.MagnumLabs.com.br - Version 1.0

  Delphi libraries for using Jurassic AI21 api

  This library is licensed under Creative Commons CC-0 (aka CC Zero),
  which means that this a public dedication tool, which allows creators to
  give up their copyright and put their works into the worldwide public domain.
  You're allowed to distribute, remix, adapt, and build upon the material
  in any medium or format, with no conditions.

  Feel free to open a push request if there's anything you want
  to contribute.

  https://studio.ai21.com/docs/api/
*)

unit MLAI21.Types;

interface

const
   AI21_ENDPOINT = 'https://api.ai21.com/studio/v1/';
   AI21_GET_COMPLETION = '/complete';
   TAI21EngineName: TArray<String> = ['j1-large', 'j1-grande', 'j1-jumbo'];

type
   TAI21Engine = (egJ1Large = 0, egJ1Grande = 1, egJ1Jumbo = 2);
   TAI21Requests = (orNone, rAuth, orEngines, orComplete);

type
   TCountPenalty = record
      Scale: Single;
      ApplyToWhitespaces: Boolean;
      ApplyToPunctuations: Boolean;
      ApplyToStopwords: Boolean;
      ApplyToEmojis: Boolean;
      ApplyToNumbers: Boolean;
   end;

   TFrequencyPenalty = record
      Scale: Single;
      ApplyToNumbers: Boolean;
      ApplyToPunctuations: Boolean;
      ApplyToStopwords: Boolean;
      ApplyToWhitespaces: Boolean;
      ApplyToEmojis: Boolean;
   end;

   TPresencePenalty = record
      Scale: Single;
      ApplyToNumbers: Boolean;
      ApplyToPunctuations: Boolean;
      ApplyToStopwords: Boolean;
      ApplyToWhitespaces: Boolean;
      ApplyToEmojis: Boolean;
   end;

implementation

end.
