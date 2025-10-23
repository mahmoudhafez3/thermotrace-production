package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing blade inspections
type SmartContract struct {
	contractapi.Contract
}

// BladeInspection represents a chord measurement inspection record
type BladeInspection struct {
	PartNumber     string            `json:"partNumber"`
	SerialNumber   string            `json:"serialNumber"`
	OccasionLabel  string            `json:"occasionLabel"`  // e.g., "before_surfacing", "manual", "after_surfacing"
	InspectionDate string            `json:"inspectionDate"` // ISO 8601 format: "2025-10-20T08:00:00Z"
	SubmittedAt    string            `json:"submittedAt"`    // ISO 8601 format
	Inspector      string            `json:"inspector"`
	Organization   string            `json:"organization"`
	Measurements   ChordMeasurements `json:"measurements"`
	CSVHash        string            `json:"csvHash"`
	
	// Blockchain metadata (populated by GetBladeHistory)
	TxID               string `json:"txId,omitempty"`
	BlockchainTimestamp string `json:"blockchainTimestamp,omitempty"` // ISO 8601 format
}

// ChordMeasurements stores the 14 chord measurement points (all in mm)
type ChordMeasurements struct {
	AR float64 `json:"ar"`
	AP float64 `json:"ap"`
	AN float64 `json:"an"`
	AM float64 `json:"am"`
	AL float64 `json:"al"`
	AK float64 `json:"ak"`
	AJ float64 `json:"aj"`
	AH float64 `json:"ah"`
	AG float64 `json:"ag"`
	AF float64 `json:"af"`
	AE float64 `json:"ae"`
	AD float64 `json:"ad"`
	AC float64 `json:"ac"`
	AB float64 `json:"ab"`
}

// InitLedger initializes the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("Blade Inspection Chaincode initialized")
	return nil
}

// AddInspection adds a new blade inspection (overwrites previous in world state)
func (s *SmartContract) AddInspection(ctx contractapi.TransactionContextInterface, inspectionJSON string) error {
	var inspection BladeInspection
	err := json.Unmarshal([]byte(inspectionJSON), &inspection)
	if err != nil {
		return fmt.Errorf("failed to unmarshal inspection: %v", err)
	}

	// Validate required fields
	if inspection.PartNumber == "" || inspection.SerialNumber == "" {
		return fmt.Errorf("partNumber and serialNumber are required")
	}

	// Create composite key: PartNumber_SerialNumber (no timestamp/occasion)
	key := fmt.Sprintf("%s_%s", inspection.PartNumber, inspection.SerialNumber)

	inspectionJSON_bytes, err := json.Marshal(inspection)
	if err != nil {
		return fmt.Errorf("failed to marshal inspection: %v", err)
	}

	// This will overwrite any existing record in world state
	// Previous versions are preserved in blockchain history
	return ctx.GetStub().PutState(key, inspectionJSON_bytes)
}

// GetInspection retrieves the current (latest) inspection for a blade
func (s *SmartContract) GetInspection(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) (*BladeInspection, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)
	inspectionJSON, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if inspectionJSON == nil {
		return nil, fmt.Errorf("inspection %s does not exist", key)
	}

	var inspection BladeInspection
	err = json.Unmarshal(inspectionJSON, &inspection)
	if err != nil {
		return nil, err
	}

	return &inspection, nil
}

// GetBladeHistory retrieves complete inspection history for a blade from blockchain
func (s *SmartContract) GetBladeHistory(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) ([]*BladeInspection, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)
	
	historyIter, err := ctx.GetStub().GetHistoryForKey(key)
	if err != nil {
		return nil, fmt.Errorf("failed to get history: %v", err)
	}
	defer historyIter.Close()

	var history []*BladeInspection
	for historyIter.HasNext() {
		modification, err := historyIter.Next()
		if err != nil {
			return nil, err
		}

		// Skip deleted records
		if modification.IsDelete {
			continue
		}

		var inspection BladeInspection
		err = json.Unmarshal(modification.Value, &inspection)
		if err != nil {
			return nil, err
		}

		// Add blockchain metadata (convert timestamp to ISO 8601 string)
		inspection.TxID = modification.TxId
		inspection.BlockchainTimestamp = fmt.Sprintf("%d.%09d", modification.Timestamp.Seconds, modification.Timestamp.Nanos)

		history = append(history, &inspection)
	}

	return history, nil
}

// GetAllInspections retrieves current inspection status for all blades
func (s *SmartContract) GetAllInspections(ctx contractapi.TransactionContextInterface) ([]*BladeInspection, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var inspections []*BladeInspection
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var inspection BladeInspection
		err = json.Unmarshal(queryResponse.Value, &inspection)
		if err != nil {
			return nil, err
		}
		inspections = append(inspections, &inspection)
	}

	return inspections, nil
}

// InspectionExists checks if a blade has any inspection record
func (s *SmartContract) InspectionExists(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) (bool, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)
	inspectionJSON, err := ctx.GetStub().GetState(key)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return inspectionJSON != nil, nil
}

// GetInspectionCount returns total number of unique blades with inspections
func (s *SmartContract) GetInspectionCount(ctx contractapi.TransactionContextInterface) (int, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return 0, err
	}
	defer resultsIterator.Close()

	count := 0
	for resultsIterator.HasNext() {
		_, err := resultsIterator.Next()
		if err != nil {
			return 0, err
		}
		count++
	}

	return count, nil
}

// GetInspectionsByOccasion retrieves all current inspections with a specific occasion label
func (s *SmartContract) GetInspectionsByOccasion(ctx contractapi.TransactionContextInterface, occasionLabel string) ([]*BladeInspection, error) {
	queryString := fmt.Sprintf(`{
		"selector": {
			"occasionLabel": "%s"
		}
	}`, occasionLabel)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var inspections []*BladeInspection
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var inspection BladeInspection
		err = json.Unmarshal(queryResponse.Value, &inspection)
		if err != nil {
			return nil, err
		}
		inspections = append(inspections, &inspection)
	}

	return inspections, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating blade inspection chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting blade inspection chaincode: %v\n", err)
	}
}
