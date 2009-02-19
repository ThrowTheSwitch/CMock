#ifndef _ADCMODEL_H
#define _ADCMODEL_H

bool AdcModel_DoGetSample(void);
void AdcModel_ProcessInput(uint16 millivolts);

bool AdcModel_DoNothingExceptTestASpecialType(EXAMPLE_STRUCT_T ExampleStruct);

#endif // _ADCMODEL_H
