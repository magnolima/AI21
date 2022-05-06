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

unit MLAI21.Complete;

interface

uses
	System.SysUtils, System.Generics.Collections, REST.Client, REST.Types,
	System.JSON, System.Variants, MLAI21.Types;

type
	TComplete = class
	private
		FEngine, FPrompt: String;
		FMaxTokens: Integer;
		FTemperature: Single;
		FTopP: Single;
		FNumberOfCompletions: Integer;
		FLogProbabilities: Integer;
		FEcho: Boolean;
		FStop: TArray<String>;
		FCountPenalty: TCountPenalty;
		FFrequencyPenalty: TFrequencyPenalty;
		FPresencePenalty: TPresencePenalty;
		FBestOf: Integer;
		FUserParameters: TDictionary<String, String>;
		procedure SetMaxTokens(const Value: Integer);
		procedure SetEngine(const Value: String);
		procedure SetPrompt(const Value: String);
		procedure SetSamplingTemperature(const Value: Single);
		procedure SetTopP(const Value: Single);
		procedure SetNumberOfCompletions(const Value: Integer);
		procedure SetLogProbabilities(const Value: Integer);
		procedure SetEcho(const Value: Boolean);
		procedure SetStop(const Value: TArray<String>);
		procedure SetFrequencyPenalty(const Value: TFrequencyPenalty);
		procedure SetCountPenalty(const Value: TCountPenalty);
		procedure SetPresencePenalty(const Value: TPresencePenalty);
		function AddCountPenalty: TJSONObject;
		procedure ResetPresencePenalty;
		procedure ResetFrequencyPenalty;
		procedure ResetCountPenalty;
		function AddFrequencyPenalty: TJSONObject;
		function AddPresencePenalty: TJSONObject;
	public
		constructor Create(EngineIndex: Integer);
		destructor Destroy; override;
		property Engine: String write SetEngine;
		property Prompt: String write SetPrompt;
		property MaxTokens: Integer write SetMaxTokens;
		property SamplingTemperature: Single write SetSamplingTemperature;
		property TopP: Single write SetTopP;
		property NumberOfCompletions: Integer write SetNumberOfCompletions;
		property LogProbabilities: Integer write SetLogProbabilities;
		property Echo: Boolean write SetEcho;
		property Stop: TArray<String> write SetStop;
		property FrequencyPenalty: TFrequencyPenalty read FFrequencyPenalty write SetFrequencyPenalty;
		property PresencePenalty: TPresencePenalty read FPresencePenalty write SetPresencePenalty;
		property CountPenalty: TCountPenalty read FCountPenalty write SetCountPenalty;
		procedure CreateCompletion(var ABody: String);
		procedure AddStringParameter(const Name: String; Value: String);
	end;

implementation

uses
	MLAI21.Core;

{ TComplete }

procedure TComplete.SetMaxTokens(const Value: Integer);
begin
	FMaxTokens := Value;
end;

procedure TComplete.SetTopP(const Value: Single);
begin
	FTopP := Value;
end;

procedure TComplete.SetNumberOfCompletions(const Value: Integer);
begin
	FNumberOfCompletions := Value;
end;

procedure TComplete.SetPrompt(const Value: String);
begin
	FPrompt := Value;
end;

procedure TComplete.SetSamplingTemperature(const Value: Single);
begin
	FTemperature := Value;
end;

procedure TComplete.SetStop(const Value: TArray<String>);
begin
	FStop := Value;
end;

procedure TComplete.SetLogProbabilities(const Value: Integer);
begin
	FLogProbabilities := Value;
end;

procedure TComplete.SetEcho(const Value: Boolean);
begin
	FEcho := Value;
end;

procedure TComplete.SetEngine(const Value: String);
begin
	FEngine := Value;
end;

procedure TComplete.SetPresencePenalty(const Value: TPresencePenalty);
begin
	FPresencePenalty.Scale := Value.Scale;
	FPresencePenalty.ApplyToNumbers := Value.ApplyToNumbers;
	FPresencePenalty.ApplyToPunctuations := Value.ApplyToPunctuations;
	FPresencePenalty.ApplyToStopwords := Value.ApplyToStopwords;
	FPresencePenalty.ApplyToWhitespaces := Value.ApplyToWhitespaces;
	FPresencePenalty.ApplyToEmojis := Value.ApplyToEmojis;
end;

procedure TComplete.SetFrequencyPenalty(const Value: TFrequencyPenalty);
begin
	FFrequencyPenalty.Scale := Value.Scale;
	FFrequencyPenalty.ApplyToNumbers := Value.ApplyToNumbers;
	FFrequencyPenalty.ApplyToPunctuations := Value.ApplyToPunctuations;
	FFrequencyPenalty.ApplyToStopwords := Value.ApplyToStopwords;
	FFrequencyPenalty.ApplyToWhitespaces := Value.ApplyToWhitespaces;
	FFrequencyPenalty.ApplyToEmojis := Value.ApplyToEmojis;
end;

procedure TComplete.SetCountPenalty(const Value: TCountPenalty);
begin
	FCountPenalty.ApplyToPunctuations := Value.ApplyToPunctuations;
	FCountPenalty.ApplyToStopwords := Value.ApplyToStopwords;
	FCountPenalty.ApplyToEmojis := Value.ApplyToEmojis;
	FCountPenalty.ApplyToWhitespaces := Value.ApplyToWhitespaces;
	FCountPenalty.ApplyToNumbers := Value.ApplyToNumbers;
end;

procedure TComplete.AddStringParameter(const Name: String; Value: String);
begin
	FUserParameters.TryAdd(Name, Value);
end;

procedure TComplete.ResetPresencePenalty;
begin
	FPresencePenalty.Scale := 0;
	FPresencePenalty.ApplyToNumbers := false;
	FPresencePenalty.ApplyToPunctuations := false;
	FPresencePenalty.ApplyToStopwords := false;
	FPresencePenalty.ApplyToWhitespaces := false;
	FPresencePenalty.ApplyToEmojis := false;
end;

procedure TComplete.ResetFrequencyPenalty;
begin
	FFrequencyPenalty.Scale := 0;
	FFrequencyPenalty.ApplyToNumbers := false;
	FFrequencyPenalty.ApplyToPunctuations := false;
	FFrequencyPenalty.ApplyToStopwords := false;
	FFrequencyPenalty.ApplyToWhitespaces := false;
	FFrequencyPenalty.ApplyToEmojis := false;
end;

procedure TComplete.ResetCountPenalty;
begin
	FCountPenalty.Scale := 0;
	FCountPenalty.ApplyToWhitespaces := false;
	FCountPenalty.ApplyToStopwords := false;
	FCountPenalty.ApplyToPunctuations := false;
	FCountPenalty.ApplyToEmojis := false;
	FCountPenalty.ApplyToNumbers := false;
end;

constructor TComplete.Create(EngineIndex: Integer);
begin
	// Set defaults
	FEngine := TAI21EngineName[EngineIndex];
	FPrompt := '';
	FMaxTokens := 16;
	FTemperature := 1.0;
	TopP := 1.0;
	FNumberOfCompletions := 1;
	FLogProbabilities := -1;
	FEcho := false;
	FStop := nil;
	ResetPresencePenalty();
	ResetFrequencyPenalty();
	ResetCountPenalty();
	FBestOf := 1;
	FUserParameters := TDictionary<string, String>.Create;
end;

function AddJSONAttrib(AJSONObject: TJSONObject; const Attrib: String; Value: Variant): TJSONObject;
var
	JSONNumber: TJSONNumber;
	JSONBool: TJSONBool;
begin
	Result := nil;
	case VarType(Value) of
		varSmallInt, varInteger, varSingle, varDouble:
			begin
				JSONNumber := TJSONNumber.Create(Value);
				Result := AJSONObject.AddPair(TJSONPair.Create(Attrib, JSONNumber))
			end;
		varString:
			Result := AJSONObject.AddPair(Attrib, Value);
		varBoolean:
			begin
				JSONBool := TJSONBool.Create(Value);
				Result := AJSONObject.AddPair(TJSONPair.Create(Attrib, JSONBool))
			end;
	end;
end;

function TComplete.AddCountPenalty: TJSONObject;
var
	AJSONObject: TJSONObject;
begin
	AJSONObject := TJSONObject.Create;
	AddJSONAttrib(AJSONObject, 'scale', FCountPenalty.Scale);
	AddJSONAttrib(AJSONObject, 'applyToNumbers', FCountPenalty.ApplyToNumbers);
	AddJSONAttrib(AJSONObject, 'applyToPunctuations', FCountPenalty.ApplyToPunctuations);
	AddJSONAttrib(AJSONObject, 'applyToStopwords', FCountPenalty.ApplyToStopwords);
	AddJSONAttrib(AJSONObject, 'applyToWhitespaces', FCountPenalty.ApplyToWhitespaces);
	AddJSONAttrib(AJSONObject, 'applyToEmojis', FCountPenalty.ApplyToEmojis);
	Result := AJSONObject;
end;

function TComplete.AddFrequencyPenalty: TJSONObject;
var
	AJSONObject: TJSONObject;
begin
	AJSONObject := TJSONObject.Create;
	AddJSONAttrib(AJSONObject, 'scale', FFrequencyPenalty.Scale);
	AddJSONAttrib(AJSONObject, 'applyToNumbers', FFrequencyPenalty.ApplyToNumbers);
	AddJSONAttrib(AJSONObject, 'applyToPunctuations', FFrequencyPenalty.ApplyToPunctuations);
	AddJSONAttrib(AJSONObject, 'applyToStopwords', FFrequencyPenalty.ApplyToStopwords);
	AddJSONAttrib(AJSONObject, 'applyToWhitespaces', FFrequencyPenalty.ApplyToWhitespaces);
	AddJSONAttrib(AJSONObject, 'applyToEmojis', FFrequencyPenalty.ApplyToEmojis);
	Result := AJSONObject;
end;

function TComplete.AddPresencePenalty: TJSONObject;
var
	AJSONObject: TJSONObject;
begin
	AJSONObject := TJSONObject.Create;
	AddJSONAttrib(AJSONObject, 'scale', FPresencePenalty.Scale);
	AddJSONAttrib(AJSONObject, 'applyToNumbers', PresencePenalty.ApplyToNumbers);
	AddJSONAttrib(AJSONObject, 'applyToPunctuations', PresencePenalty.ApplyToPunctuations);
	AddJSONAttrib(AJSONObject, 'applyToStopwords', PresencePenalty.ApplyToStopwords);
	AddJSONAttrib(AJSONObject, 'applyToWhitespaces', PresencePenalty.ApplyToWhitespaces);
	AddJSONAttrib(AJSONObject, 'applyToEmojis', PresencePenalty.ApplyToEmojis);
	Result := AJSONObject;
end;

procedure TComplete.CreateCompletion(var ABody: String);
var
	AJSONObject: TJSONObject;
	Value, Stop: String;
	JSONNumber: TJSONNumber;
	JSONArray: TJSONArray;
begin
	AJSONObject := TJSONObject.Create;
	AJSONObject.AddPair(TJSONPair.Create('prompt', FPrompt));
	AJSONObject.AddPair(TJSONPair.Create('numResults', TJSONNumber.Create(FNumberOfCompletions)));
	AJSONObject.AddPair(TJSONPair.Create('maxTokens', TJSONNumber.Create(FMaxTokens)));
	AJSONObject.AddPair(TJSONPair.Create('temperature', TJSONNumber.Create(Trunc(FTemperature * 100) / 100)));

	if FLogProbabilities <> -1 then
		AJSONObject.AddPair(TJSONPair.Create('topKReturn', TJSONNumber.Create(FLogProbabilities)));

	AJSONObject.AddPair(TJSONPair.Create('topP', TJSONNumber.Create(Trunc(FTopP * 100) / 100)));
	AJSONObject.AddPair(TJSONPair.Create('countPenalty', AddCountPenalty()));
	AJSONObject.AddPair(TJSONPair.Create('frequencyPenalty', AddFrequencyPenalty()));
	AJSONObject.AddPair(TJSONPair.Create('presencePenalty', AddPresencePenalty()));

	if Length(FStop) > 0 then
	begin
		JSONArray := TJSONArray.Create;
		for Stop in FStop do
			JSONArray.Add(Stop);
		AJSONObject.AddPair(TJSONPair.Create('stopSequences', JSONArray));
	end;

	// if Length(FStop) = 0 then
	// AJSONObject.AddPair(TJSONPair.Create('stopSequences', TJSONArray.Create))
	// else
	// for Stop in FStop do
	// AJSONObject.AddPair(TJSONPair.Create('stopSequences', Stop));

	for Value in FUserParameters.Keys do
		AJSONObject.AddPair(TJSONPair.Create(Value, FUserParameters[Value]));

	ABody := AJSONObject.ToJSON;
	AJSONObject.Free;

end;

destructor TComplete.Destroy;
begin
	FUserParameters.Free;
	inherited;
end;

end.
