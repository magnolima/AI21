(*
  (C)2021-2022 Magno Lima - www.MagnumLabs.com.br

  THIS IS A TEST FILE TO USE WITH OPENAI GPT-3 API
  ** YOU WILL NEED YOUR OWN KEY TO BE ABLE TO USE THIS SOFTWARE **

  Delphi libraries for using OpenAI's GPT-3 api

  This library is licensed under Creative Commons CC-0 (aka CC Zero),
  which means that this a public dedication tool, which allows creators to
  give up their copyright and put their works into the worldwide public domain.
  You're allowed to distribute, remix, adapt, and build upon the material
  in any medium or format, with no conditions.

  Feel free to open a push request if there's anything you want
  to contribute.

  https://beta.openai.com/docs/api-reference/engines/retrieve
*)
unit uDemoAI21;

interface

uses
	System.SysUtils, System.Types, System.UITypes, System.Classes,
	System.Variants,
	FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.IOUtils,
	FMX.StdCtrls, FMX.Controls.Presentation, FireDAC.Stan.Intf,
	FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
	FireDAC.Phys.Intf, FireDAC.DApt.Intf, System.Rtti, FMX.Grid.Style,
	Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid, System.Bindings.Outputs,
	FMX.Bind.Editors, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
	Data.DB, FMX.Grid, FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.ScrollBox,
	FMX.Memo, FMX.Edit, Data.Bind.ObjectScope, REST.Client, REST.Response.Adapter,
	FMX.Objects, FMX.TabControl, FMX.EditBox, FMX.NumberBox, FMX.Memo.Types,
	REST.Types, System.Generics.Collections,
	MLAI21.Types;

const
	APIKey_Filename = '.\ai21.key';

type
	TfrmDemoAI21 = class(TForm)
		ToolBar1: TToolBar;
		mmPrompt: TMemo;
		FDMemTable1: TFDMemTable;
		DataSource1: TDataSource;
		BindingsList1: TBindingsList;
		Label1: TLabel;
		Button1: TButton;
		Panel1: TPanel;
		AniIndicator1: TAniIndicator;
		TabControl1: TTabControl;
		TabItem2: TTabItem;
		Label3: TLabel;
		Label4: TLabel;
		Edit1: TEdit;
		Label8: TLabel;
		mmResponse: TMemo;
		RESTClient1: TRESTClient;
		RESTRequest1: TRESTRequest;
		RESTResponse1: TRESTResponse;
		Button2: TButton;
		ToolBar2: TToolBar;
		lbEngine: TLabel;
		Image1: TImage;
		rbTJ1Grande: TRadioButton;
		rbJ1Jumbo: TRadioButton;
		rbJ1Large: TRadioButton;
		tbTemperature: TTrackBar;
		Label5: TLabel;
		nbMaxTokens: TTrackBar;
		nbTopP: TTrackBar;
		Label2: TLabel;
		lbMaxTokens: TLabel;
		lbTemperature: TLabel;
		lbTopP: TLabel;
		Button3: TButton;
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure Button1Click(Sender: TObject);
		procedure rbEngineSelect(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure Button2Click(Sender: TObject);
		procedure nbMaxTokensChange(Sender: TObject);
		procedure tbTemperatureChange(Sender: TObject);
		procedure nbTopPChange(Sender: TObject);
		procedure Button3Click(Sender: TObject);
	private
		procedure InitCompletions;
		procedure OnOpenAIError(Sender: TObject);
		function GetResult: String;
		{ Private declarations }
	public
		{ Public declarations }
		procedure OnOpenAIResponse(Sender: TObject);
	end;

var
	frmDemoAI21: TfrmDemoAI21;
	EngineIndex: Integer;
	NameOfEngines: TArray<String>;

implementation

uses
	System.JSON,
	MLAI21.Core, MLAI21.Complete;

var
	AI21: TAI21;

{$R *.fmx}

function SliceString(const AString: string; const ADelimiter: string): TArray<String>;
var
	I: Integer;
	p: ^Integer;
	PLine, PStart: PChar;
	s: String;
begin

	I := 1;
	PLine := PChar(AString);

	PStart := PLine;
	inc(PLine);

	while (I < length(AString)) do
	begin
		while (PLine^ <> #0) and (PLine^ <> ADelimiter) do
		begin
			inc(PLine);
			inc(I);
		end;

		SetString(s, PStart, PLine - PStart);
		SetLength(Result, length(Result) + 1);
		Result[length(Result) - 1] := s;
		inc(PLine);
		inc(I);
		PStart := PLine;
	end;

end;

procedure TfrmDemoAI21.OnOpenAIError(Sender: TObject);
begin
	if AI21.StatusCode = 422 then
		mmResponse.Lines.Add('Unprocessed error, check your parameters. Error 422.')
	else
		mmResponse.Lines.Add('Error ' + AI21.StatusCode.ToString + ' - ' + AI21.ErrorMessage);
end;

procedure TfrmDemoAI21.FormCreate(Sender: TObject);
begin
	NameOfEngines := TAI21EngineName;
	// Store your key safely. Never share or expose it!
	AI21 := TAI21.Create(FDMemTable1, APIKey_Filename);
	AI21.Endpoint := AI21_ENDPOINT;
	AI21.Engine := TAI21Engine.egJ1Grande;
	AI21.OnResponse := OnOpenAIResponse;
	AI21.OnError := OnOpenAIError;
	EngineIndex := Ord(AI21.Engine);
end;

procedure TfrmDemoAI21.FormDestroy(Sender: TObject);
begin
	AI21.DisposeOf;
end;

procedure TfrmDemoAI21.Button2Click(Sender: TObject);
begin
	mmResponse.Lines.Clear;
end;

procedure TfrmDemoAI21.Button3Click(Sender: TObject);
begin
	mmResponse.Lines.Text := GetResult;
end;

procedure TfrmDemoAI21.FormShow(Sender: TObject);
begin
	AI21.RequestType := orComplete;
	lbMaxTokens.Text := Round(nbMaxTokens.Value).ToString;
	lbTopP.Text := Format('%0.2f', [nbTopP.Value]);
	lbTemperature.Text := Format('%0.2f', [tbTemperature.Value]);
	lbEngine.Text := 'Engine: ' + NameOfEngines[Ord(EngineIndex)];
end;

function IfThen(const Test: Boolean; IsTrue, IsFalse: String): String;
begin
	if Test then
		Result := IsTrue
	else
		Result := IsFalse;
end;

procedure TfrmDemoAI21.OnOpenAIResponse(Sender: TObject);
var
	field: TField;
	Engine: TPair<string, string>;
begin
	Button1.Enabled := True;
	AniIndicator1.Enabled := False;
	mmResponse.Lines.Add('GetChoicesResult='+AI21.GetChoicesResult);
	mmResponse.Lines.Add('------------------------------------------');
	FDMemTable1.First;
	while not FDMemTable1.Eof do
	begin
		mmResponse.Lines.Add('{');
		for field in FDMemTable1.Fields do
			mmResponse.Lines.Add(field.FieldName + ': "' + Trim(field.AsString) + '"' + IfThen(field.Index = FDMemTable1.Fields.Count - 1, '', ',')
			  + IfThen(field.Index = FDMemTable1.Fields.Count - 1, '', #13));
		mmResponse.Lines.Add('}');
		FDMemTable1.Next;
	end;

end;

procedure TfrmDemoAI21.rbEngineSelect(Sender: TObject);
begin
	EngineIndex := (Sender as TRadioButton).Tag;
	lbEngine.Text := 'Engine: ' + NameOfEngines[Ord(EngineIndex)];
end;

procedure TfrmDemoAI21.nbMaxTokensChange(Sender: TObject);
begin
	lbMaxTokens.Text := Round(nbMaxTokens.Value).ToString;
end;

procedure TfrmDemoAI21.tbTemperatureChange(Sender: TObject);
begin
	lbTemperature.Text := Format('%0.2f', [tbTemperature.Value]);
end;

procedure TfrmDemoAI21.nbTopPChange(Sender: TObject);
begin
	lbTopP.Text := Format('%0.2f', [nbTopP.Value]);
end;

procedure TfrmDemoAI21.InitCompletions;
var
	ACompletions: TComplete;
	I: Integer;
	sPrompt: String;

	function getStops(Text: String): TArray<String>;
	begin
		Result := SliceString(Text, ';');
	end;

begin

	sPrompt := mmPrompt.Text.Trim;

	if sPrompt.IsEmpty then
	begin
		ShowMessage('A prompt text must be supplied');
		Exit;
	end;

	ACompletions := TComplete.Create(EngineIndex);
	ACompletions.MaxTokens := Round(nbMaxTokens.Value);
	ACompletions.SamplingTemperature := tbTemperature.Value;
	ACompletions.TopP := nbTopP.Value;
	ACompletions.Stop := getStops(Edit1.Text);
	ACompletions.Prompt := sPrompt;
	ACompletions.LogProbabilities := -1; // -1 will set as null default
	// ACompletions.FrequencyPenalty := ;
	// ACompletions.PresencePenalty := 0.1;
	AI21.Completions := ACompletions;

	case EngineIndex of
		0:
			AI21.Engine := TAI21Engine.egJ1Large;
		1:
			AI21.Engine := TAI21Engine.egJ1Grande;
		2:
			AI21.Engine := TAI21Engine.egJ1Jumbo;
	end;

	AI21.RequestType := orComplete;
	AI21.Endpoint := AI21_ENDPOINT + NameOfEngines[EngineIndex];

end;

procedure TfrmDemoAI21.Button1Click(Sender: TObject);
begin
	if AI21.APIKey.IsEmpty then
	begin
		mmResponse.Lines.Add('API key is missing');
		Exit;
	end;

	if (AI21.RequestType = orComplete) and (mmPrompt.Text.IsEmpty) then
	begin
		mmResponse.Lines.Add('The prompt can''t be empty');
		mmPrompt.SetFocus;
		Exit;
	end;

	if AI21.RequestType = orNone then
	begin
		mmResponse.Lines.Add('Choose a request type.');
		Exit;
	end;

	Button1.Enabled := False;
	AniIndicator1.Enabled := True;
	AniIndicator1.Visible := True;

	TThread.CreateAnonymousThread(
		procedure
		begin
			try
				InitCompletions();

				try
					AI21.Execute;
				except
					on E: Exception do
						mmResponse.Lines.Add(E.Message)
				end;

			finally
				Button1.Enabled := True;
				AniIndicator1.Enabled := False;
				AniIndicator1.Visible := False;
			end;

		end).Start;
end;

function TfrmDemoAI21.GetResult: String;
var
  vJSONBytes: TBytes;
  vJSONScenario: TJSONValue;
  vJSONArray: TJSONArray;
  vJSONValue: TJSONValue;
  vJSONObject: TJSONObject;
  vJSONPair: TJSONPair;
  vJSONScenarioEntry: TJSONValue;
  vJSONScenarioValue: TJSONString;
begin

  vJSONBytes := BytesOf( mmPrompt.Lines.Text);

  vJSONScenario := TJSONObject.ParseJSONValue(vJSONBytes, 0);
  if vJSONScenario <> nil then
  try
    //BetFair Specific 'caption' key
    vJSONArray := vJSONScenario as TJSONArray;
    for vJSONValue in vJSONArray do
    begin
      vJSONObject := vJSONValue as TJSONObject;
      vJSONPair := vJSONObject.Get('caption');
      vJSONScenarioEntry := vJSONPair.JsonValue;
      vJSONScenarioValue := vJSONScenarioEntry as TJSONString;
		mmResponse.lines.Add(vJSONScenarioValue.Value);
    end;
  finally
    vJSONScenario.Free;
  end;
end;
(*
function TfrmDemoAI21.GetResult: String;
var
	JSonValue: TJSonValue;
	JsonArray: TJSONArray;
	ArrayElement: TJSonValue;
	value: string;
begin
	Result := '';


 //	JSonValue := TJSonObject.ParseJSONValue(TEncoding.UTF8.GetBytes(mmPrompt.Lines.Text));
// {"id":"02e4c7e8-af64-4dce-bd86-dbf666f37ce3","prompt":{"text":"parsing the json file is","tokens":[{"generatedToken":{"token":"?parsing","logprob":-16.004453659057617},"topTokens":null,"textRange":{"start":0,"end":7}},{"generatedToken":{"token":"?the","logprob":-3.262373208999634},"topTokens":null,"textRange":{"start":7,"end":11}},{"generatedToken":{"token":"?json","logprob":-4.391495704650879},"t
	JSonValue := TJSonObject.ParseJSONValue('id');
	JsonArray := JSonValue.GetValue<TJSONArray>('id');
	for value in jsonvalue.ToString do
		result := result + value;

//	Result := '';
//
//	JSonValue := TJSonObject.ParseJSONValue(FBodyContent);
//	JsonArray := JSonValue.GetValue<TJSONArray>('choices');
//	for ArrayElement in JsonArray do
//		Result := Result + ArrayElement.GetValue<String>('text');

end;
*)
end.
