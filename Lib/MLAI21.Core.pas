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

unit MLAI21.Core;

interface

uses
   System.Diagnostics, System.Classes, System.SysUtils, Data.Bind.Components,
   Data.Bind.ObjectScope, REST.Client, REST.Types,
   FireDAC.Stan.Intf,
   FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
   REST.Response.Adapter,
   FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, System.StrUtils,
   System.Generics.Collections,
   Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.Types,
   System.IOUtils, System.TypInfo, System.JSON,
   MLAI21.Types, MLAI21.Complete;

type
   TRESTRequestOAI = class(TRESTRequest)
   private
      FRequestType: TAI21Requests;
      property RequestType: TAI21Requests read FRequestType write FRequestType;
   end;

type
   TAI21 = class(TObject)
   private
      //
      FAcceptType: String;
      FContentType: String;
      FEndpoint: String;
      FResource: String;
      FErrorMessage: String;
      FBodyContent: String;
      FEngine: TAI21Engine;
      FRequestType: TAI21Requests;
      FEnginesList: TDictionary<String, String>;
      FOnResponse: TNotifyEvent;
      FOnError: TNotifyEvent;
      FAPIKey: String;
      FOrganization: String;
      FRESTRequest: TRESTRequestOAI;
      FRESTClient: TRESTClient;
      FRESTResponse: TRESTResponse;
		FMemtable: TFDMemTable;
      FCompletions: TComplete;
      FStatusCode: Integer;
      procedure readEngines;
      procedure SetEndPoint(const Value: String);
      procedure SetApiKey(const Value: string);
      procedure SetOrganization(const Value: String);
      procedure SetEngine(const Value: TAI21Engine);
      procedure SetCompletions(const Value: TComplete);
      procedure CreateRESTRespose;
      procedure CreateRESTClient;
      procedure CreateRESTRequest;
      procedure ExecuteCompletions;
      procedure HttpRequestError(Sender: TCustomRESTRequest);
      procedure HttpClientError(Sender: TCustomRESTClient);
   public
      constructor Create(var MemTable: TFDMemTable; const APIFileName: String = '');
      destructor Destroy; Override;
      // procedure HttpError(Sender: TCustomRESTClient);
      property ErrorMessage: String read FErrorMessage;
   published
      procedure Execute;
      procedure Stop;
      function GetChoicesResult: String;
      procedure AfterExecute(Sender: TCustomRESTRequest);
      property OnResponse: TNotifyEvent read FOnResponse write FOnResponse;
      property OnError: TNotifyEvent read FOnError write FOnError;
      property StatusCode: Integer read FStatusCode;
      property Engine: TAI21Engine read FEngine write SetEngine;
      property Endpoint: String read FEndpoint write SetEndPoint;
      property Organization: String read FOrganization write SetOrganization;
      property APIKey: String read FAPIKey write SetApiKey;
      property AvailableEngines: TDictionary<String, String> read FEnginesList;
      property RequestType: TAI21Requests read FRequestType write FRequestType;
      property Completions: TComplete write SetCompletions;
      property BodyContent: String read FBodyContent;
   end;

implementation

{ TOpenAI }

function SliceString(const AString: string; const ADelimiter: string): TArray<String>;
var
   I: Integer;
   PLine, PStart: PChar;
   s: String;
begin

   I := 1;
   PLine := PChar(AString);

   PStart := PLine;
   inc(PLine);

   while (I < Length(AString)) do
   begin
      while (PLine^ <> #0) and (PLine^ <> ADelimiter) do
      begin
         inc(PLine);
         inc(I);
      end;

      SetString(s, PStart, PLine - PStart);
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := s;
      inc(PLine);
      inc(I);
      PStart := PLine;
   end;

end;

procedure TAI21.CreateRESTRespose;
begin
   FAcceptType := 'application/json';
   FContentType := 'application/json';
   //
   FRESTResponse := TRESTResponse.Create(nil);
   FRESTResponse.Name := '_restresponse';
   FRESTResponse.ContentType := FContentType;
end;

procedure TAI21.CreateRESTClient;
begin
   FRESTClient := TRESTClient.Create(nil);
   FRESTClient.AcceptCharset := 'UTF-8';
   FRESTClient.UserAgent := 'MagnumLabsAI21Client';
   FRESTClient.Accept := FAcceptType;
   FRESTClient.ContentType := FContentType;
   FRESTClient.OnHTTPProtocolError := HttpClientError;
end;

procedure TAI21.CreateRESTRequest;
begin
   FRESTRequest := TRESTRequestOAI.Create(nil);
   FRESTRequest.AcceptCharset := 'UTF-8';
   FRESTRequest.Accept := FAcceptType;
   FRESTRequest.Method := TRESTRequestMethod.rmPOST;
   FRESTRequest.Params.Clear;
   FRESTRequest.Body.ClearBody;
   FRESTRequest.Response := FRESTResponse;
   FRESTRequest.Client := FRESTClient;
   FRESTRequest.OnAfterExecute := AfterExecute;
   FRESTRequest.FRequestType := TAI21Requests.orNone;
   FRESTRequest.OnHTTPProtocolError := HttpRequestError;
end;

constructor TAI21.Create(var MemTable: TFDMemTable; const APIFileName: String = '');
var
   fileName: String;
begin
   FErrorMessage := '';
   FOnResponse := nil;
   FMemtable := MemTable;
   //
   CreateRESTRespose();
   //
   CreateRESTClient();
   //
   CreateRESTRequest();

{$IF Defined(ANDROID)}
   fileName := TPath.Combine(TPath.GetDocumentsPath, APIFileName);
{$ELSE}
   fileName := APIFileName;
{$ENDIF}
   if not APIFileName.IsEmpty and FileExists(fileName) then
   begin
      FAPIKey := TFile.ReadAllText(fileName);
      SetApiKey(FAPIKey);
   end;

end;

destructor TAI21.Destroy;
begin
   FRESTResponse.Free;
   FRESTRequest.Free;
	FRESTClient.Free;
   inherited Destroy;
end;

procedure TAI21.HttpRequestError(Sender: TCustomRESTRequest);
begin
   FRESTRequest.FRequestType := orNone;
   FStatusCode := FRESTRequest.Response.StatusCode;
   FErrorMessage := 'Request error: ' + FRESTRequest.Response.StatusCode.ToString;
   FOnError(Self);
end;

procedure TAI21.HttpClientError(Sender: TCustomRESTClient);
begin
   FRESTRequest.FRequestType := orNone;
   FErrorMessage := FRESTRequest.Response.ErrorMessage;
   FOnError(Self);
end;

procedure TAI21.SetEndPoint(const Value: String);
begin
   FEndpoint := Value;
   FRESTClient.BaseURL := Value;
end;

procedure TAI21.SetEngine(const Value: TAI21Engine);
begin
   FEngine := Value;
end;

procedure TAI21.SetOrganization(const Value: String);
begin
   FOrganization := Value;
end;

procedure TAI21.Stop;
begin
   FRESTRequest.FRequestType := orNone;
end;

function TAI21.GetChoicesResult: String;
var
   JSonValue: TJSonValue;
   JsonArray: TJSONArray;
   ArrayElement: TJSonValue;
begin
  Result := '';

{	JSonValue := TJSonObject.ParseJSONValue(FBodyContent);

  JSonValue.TryGetValue<TJSONArray>('data',JsonArray);


  //	JsonArray := JSonValue.GetValue<TJSONArray>('data');
	for ArrayElement in JsonArray do
		Result := Result + ArrayElement.GetValue<String>('text');
}
end;

procedure TAI21.readEngines();
begin
   if not Assigned(FEnginesList) then
      FEnginesList := TDictionary<String, String>.Create;

   FEnginesList.Clear;
   while not FMemtable.Eof do
   begin
      FEnginesList.Add(FMemtable.FieldByName('id').AsString, FMemtable.FieldByName('ready').AsString);
      FMemtable.Next;
   end;

end;

procedure TAI21.AfterExecute(Sender: TCustomRESTRequest);
var
	LStatusCode: Integer;
	FRESTResponseDataSetAdapter: TRESTResponseDataSetAdapter;
begin

   LStatusCode := FRESTResponse.StatusCode;

   if FStatusCode = 0 then
      FStatusCode := LStatusCode;

   if not(FStatusCode in [200, 201]) then
		Exit;

	FBodyContent := FRESTResponse.Content;

	case FRequestType of
		orEngines:
			FRESTResponse.RootElement := 'data';
		orComplete:
			FRESTResponse.RootElement := 'completions';
	end;

	if not FMemtable.IsEmpty then
      FMemtable.EmptyDataSet;

   FRESTResponseDataSetAdapter := TRESTResponseDataSetAdapter.Create(nil);
   try
      FRESTResponseDataSetAdapter.DataSet := FMemtable;
      FRESTResponseDataSetAdapter.Response := FRESTResponse;
      FMemtable.First;
   finally
      FRESTResponseDataSetAdapter.Free;
   end;

   FRESTRequest.FRequestType := orNone;
   if Assigned(FOnResponse) then
      FOnResponse(Self);
end;

procedure TAI21.SetApiKey(const Value: string);
begin
   FAPIKey := Value;
   FRESTRequest.Params.AddHeader('Authorization', 'Bearer ' + FAPIKey);
   FRESTRequest.Params.ParameterByName('Authorization').Options := [poDoNotEncode];
end;

procedure TAI21.SetCompletions(const Value: TComplete);
begin
   FCompletions := Value;
end;

procedure TAI21.Execute;
begin
   if not FMemtable.IsEmpty then
      FMemtable.EmptyDataSet;
   case FRequestType of
      orComplete:
         ExecuteCompletions();
   end;
end;

procedure TAI21.ExecuteCompletions;
var
   ABody: String;
begin
   FRESTRequest.ClearBody;
   FCompletions.CreateCompletion(ABody);
   FRESTRequest.Resource := AI21_GET_COMPLETION;
   FRESTRequest.Body.Add(ABody, TRESTContentType.ctAPPLICATION_JSON);
   FRESTRequest.Method := TRESTRequestMethod.rmPOST;
   FRESTRequest.Execute;
end;

end.
