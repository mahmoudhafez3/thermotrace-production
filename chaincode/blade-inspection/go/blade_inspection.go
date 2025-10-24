package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing blade inspections
type SmartContract struct {
	contractapi.Contract
}

// BladeInspection represents a chord measurement inspection record (complete view)
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
	TxID                string `json:"txId,omitempty"`
	BlockchainTimestamp string `json:"blockchainTimestamp,omitempty"` // ISO 8601 format
}

// BladeInspectionPublic represents the public data (all fields except Inspector)
type BladeInspectionPublic struct {
	PartNumber     string            `json:"partNumber"`
	SerialNumber   string            `json:"serialNumber"`
	OccasionLabel  string            `json:"occasionLabel"`
	InspectionDate string            `json:"inspectionDate"`
	SubmittedAt    string            `json:"submittedAt"`
	Organization   string            `json:"organization"`
	Measurements   ChordMeasurements `json:"measurements"`
	CSVHash        string            `json:"csvHash"`

	// Blockchain metadata
	TxID                string `json:"txId,omitempty"`
	BlockchainTimestamp string `json:"blockchainTimestamp,omitempty"`
}

// BladeInspectionPrivate represents the private data (Inspector only)
type BladeInspectionPrivate struct {
	Inspector string `json:"inspector"`
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

// AddInspection adds a new blade inspection using PDC (overwrites previous in world state)
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

	// Get the client's MSP ID to determine which private collection to use
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get client MSP ID: %v", err)
	}

	// Determine the org-specific private collection name
	var privateCollectionName string
	switch clientMSPID {
	case "ManufacturerMSP":
		privateCollectionName = "inspectionPrivateManufacturerCollection"
	case "MROLabMSP":
		privateCollectionName = "inspectionPrivateMROLabCollection"
	default:
		return fmt.Errorf("unknown MSP ID: %s", clientMSPID)
	}

	// Create composite key: PartNumber_SerialNumber (no timestamp/occasion)
	key := fmt.Sprintf("%s_%s", inspection.PartNumber, inspection.SerialNumber)

	// Split into public and private data
	publicData := BladeInspectionPublic{
		PartNumber:     inspection.PartNumber,
		SerialNumber:   inspection.SerialNumber,
		OccasionLabel:  inspection.OccasionLabel,
		InspectionDate: inspection.InspectionDate,
		SubmittedAt:    inspection.SubmittedAt,
		Organization:   inspection.Organization,
		Measurements:   inspection.Measurements,
		CSVHash:        inspection.CSVHash,
	}

	privateData := BladeInspectionPrivate{
		Inspector: inspection.Inspector,
	}

	// Marshal public data
	publicDataBytes, err := json.Marshal(publicData)
	if err != nil {
		return fmt.Errorf("failed to marshal public data: %v", err)
	}

	// Marshal private data
	privateDataBytes, err := json.Marshal(privateData)
	if err != nil {
		return fmt.Errorf("failed to marshal private data: %v", err)
	}

	// Write public data to public collection
	err = ctx.GetStub().PutPrivateData("inspectionPublicCollection", key, publicDataBytes)
	if err != nil {
		return fmt.Errorf("failed to write public data: %v", err)
	}

	// Write private data to org-specific private collection
	err = ctx.GetStub().PutPrivateData(privateCollectionName, key, privateDataBytes)
	if err != nil {
		return fmt.Errorf("failed to write private data: %v", err)
	}

	return nil
}

// GetInspection retrieves the current (latest) inspection for a blade (public + private data if accessible)
func (s *SmartContract) GetInspection(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) (*BladeInspection, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)

	// Get public data
	publicDataBytes, err := ctx.GetStub().GetPrivateData("inspectionPublicCollection", key)
	if err != nil {
		return nil, fmt.Errorf("failed to read public data: %v", err)
	}
	if publicDataBytes == nil {
		return nil, fmt.Errorf("inspection %s does not exist", key)
	}

	var publicData BladeInspectionPublic
	err = json.Unmarshal(publicDataBytes, &publicData)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal public data: %v", err)
	}

	// Get the client's MSP ID to determine which private collection to read from
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get client MSP ID: %v", err)
	}

	// Determine the org-specific private collection name
	var privateCollectionName string
	switch clientMSPID {
	case "ManufacturerMSP":
		privateCollectionName = "inspectionPrivateManufacturerCollection"
	case "MROLabMSP":
		privateCollectionName = "inspectionPrivateMROLabCollection"
	default:
		return nil, fmt.Errorf("unknown MSP ID: %s", clientMSPID)
	}

	// Try to get private data (Inspector) from org-specific collection
	privateDataBytes, err := ctx.GetStub().GetPrivateData(privateCollectionName, key)
	// Don't fail if private data doesn't exist - it might have been submitted by another org

	var privateData BladeInspectionPrivate
	if err == nil && privateDataBytes != nil {
		err = json.Unmarshal(privateDataBytes, &privateData)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal private data: %v", err)
		}
	}

	// Combine public and private data
	inspection := BladeInspection{
		PartNumber:     publicData.PartNumber,
		SerialNumber:   publicData.SerialNumber,
		OccasionLabel:  publicData.OccasionLabel,
		InspectionDate: publicData.InspectionDate,
		SubmittedAt:    publicData.SubmittedAt,
		Inspector:      privateData.Inspector,
		Organization:   publicData.Organization,
		Measurements:   publicData.Measurements,
		CSVHash:        publicData.CSVHash,
	}

	// Add blockchain metadata for current query
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err == nil {
		t := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))
		inspection.BlockchainTimestamp = t.Format(time.RFC3339)
	}
	inspection.TxID = ctx.GetStub().GetTxID()

	return &inspection, nil
}

// GetInspectionPublic retrieves only public data (without Inspector name)
func (s *SmartContract) GetInspectionPublic(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) (*BladeInspectionPublic, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)

	// Get public data only
	publicDataBytes, err := ctx.GetStub().GetPrivateData("inspectionPublicCollection", key)
	if err != nil {
		return nil, fmt.Errorf("failed to read public data: %v", err)
	}
	if publicDataBytes == nil {
		return nil, fmt.Errorf("inspection %s does not exist", key)
	}

	var publicData BladeInspectionPublic
	err = json.Unmarshal(publicDataBytes, &publicData)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal public data: %v", err)
	}

	// Add blockchain metadata
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err == nil {
		t := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))
		publicData.BlockchainTimestamp = t.Format(time.RFC3339)
	}
	publicData.TxID = ctx.GetStub().GetTxID()

	return &publicData, nil
}

// GetInspectionPrivate retrieves only private data (Inspector name - only for owning org)
func (s *SmartContract) GetInspectionPrivate(ctx contractapi.TransactionContextInterface, partNumber, serialNumber string) (*BladeInspectionPrivate, error) {
	key := fmt.Sprintf("%s_%s", partNumber, serialNumber)

	// Get private data only (will fail if caller is not from the owning org)
	privateDataBytes, err := ctx.GetStub().GetPrivateData("inspectionPrivateCollection", key)
	if err != nil {
		return nil, fmt.Errorf("failed to read private data: %v", err)
	}
	if privateDataBytes == nil {
		return nil, fmt.Errorf("private data for inspection %s does not exist", key)
	}

	var privateData BladeInspectionPrivate
	err = json.Unmarshal(privateDataBytes, &privateData)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal private data: %v", err)
	}

	return &privateData, nil
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

		// // Add blockchain metadata (convert timestamp to ISO 8601 string)
		// inspection.TxID = modification.TxId
		// inspection.BlockchainTimestamp = fmt.Sprintf("%d.%09d", modification.Timestamp.Seconds, modification.Timestamp.Nanos)
		// Add blockchain metadata (convert timestamp to ISO 8601 string)
		inspection.TxID = modification.TxId
		t := time.Unix(modification.Timestamp.Seconds, int64(modification.Timestamp.Nanos))
		inspection.BlockchainTimestamp = t.Format(time.RFC3339)

		history = append(history, &inspection)
	}

	return history, nil
}

// // GetAllInspections retrieves current inspection status for all blades
// func (s *SmartContract) GetAllInspections(ctx contractapi.TransactionContextInterface) ([]*BladeInspection, error) {
// 	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
// 	if err != nil {
// 		return nil, err
// 	}
// 	defer resultsIterator.Close()

// 	var inspections []*BladeInspection
// 	for resultsIterator.HasNext() {
// 		queryResponse, err := resultsIterator.Next()
// 		if err != nil {
// 			return nil, err
// 		}

// 		var inspection BladeInspection
// 		err = json.Unmarshal(queryResponse.Value, &inspection)
// 		if err != nil {
// 			return nil, err
// 		}
// 		inspections = append(inspections, &inspection)
// 	}

// 	return inspections, nil
// }

// GetAllInspections retrieves current inspection status for all blades
func (s *SmartContract) GetAllInspections(ctx contractapi.TransactionContextInterface) ([]*BladeInspection, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	// Get current transaction metadata once
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	var blockchainTimestamp string
	if err == nil {
		t := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))
		blockchainTimestamp = t.Format(time.RFC3339)
	}
	txID := ctx.GetStub().GetTxID()

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

		// Add blockchain metadata
		inspection.BlockchainTimestamp = blockchainTimestamp
		inspection.TxID = txID

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
