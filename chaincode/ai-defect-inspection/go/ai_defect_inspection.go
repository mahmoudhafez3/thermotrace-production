package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing AI defect inspections
type SmartContract struct {
	contractapi.Contract
}

// AIDefectInspection represents a composite material defect inspection using AI
type AIDefectInspection struct {
	// Identity
	PartNumber   string `json:"partNumber"`
	SerialNumber string `json:"serialNumber"`
	MaterialType string `json:"materialType"`

	// Inspection Metadata
	InspectionDate string `json:"inspectionDate"`
	InspectionType string `json:"inspectionType"` // e.g., "Active Thermography"
	Inspector      string `json:"inspector"`      // Private field
	Organization   string `json:"organization"`

	// Video/Image Data (External Storage References)
	RawVideoHash       string `json:"rawVideoHash"`       // SHA-256
	RawVideoIPFS       string `json:"rawVideoIPFS"`       // IPFS CID
	RawVideoSize       int64  `json:"rawVideoSize"`       // Bytes
	ProcessedImageHash string `json:"processedImageHash"` // SHA-256
	ProcessedImageIPFS string `json:"processedImageIPFS"` // IPFS CID

	// ROI Parameters
	ROI_Y1 int `json:"roi_y1"`
	ROI_Y2 int `json:"roi_y2"`
	ROI_X1 int `json:"roi_x1"`
	ROI_X2 int `json:"roi_x2"`

	// Processing Parameters
	PulseTime      int `json:"pulseTime"`
	PCAComponents  int `json:"pcaComponents"`
	SequenceLength int `json:"sequenceLength"`

	// AI Model Information
	ModelName    string `json:"modelName"`    // e.g., "cnn_attention_grdino"
	ModelVersion string `json:"modelVersion"` // e.g., "v1.0"
	ModelHash    string `json:"modelHash"`    // Hash of model weights

	// Detection Results
	DefectDetected  bool    `json:"defectDetected"`
	DefectType      string  `json:"defectType"`      // e.g., "thermal defect"
	ConfidenceScore float64 `json:"confidenceScore"` // 0.0 to 1.0

	// Bounding Box (if defect detected)
	BBox_X1 float64 `json:"bbox_x1"`
	BBox_Y1 float64 `json:"bbox_y1"`
	BBox_X2 float64 `json:"bbox_x2"`
	BBox_Y2 float64 `json:"bbox_y2"`

	// Metrics
	IoU                float64 `json:"iou"`
	CenterDistance     float64 `json:"centerDistance"`
	NormCenterDistance float64 `json:"normCenterDistance"`

	// Ground Truth (if available)
	HasGroundTruth bool    `json:"hasGroundTruth"`
	GT_BBox_X1     float64 `json:"gt_bbox_x1"`
	GT_BBox_Y1     float64 `json:"gt_bbox_y1"`
	GT_BBox_X2     float64 `json:"gt_bbox_x2"`
	GT_BBox_Y2     float64 `json:"gt_bbox_y2"`

	// Blockchain Metadata
	TxID                string `json:"txID"`
	BlockchainTimestamp string `json:"blockchainTimestamp"`
	SubmittedAt         string `json:"submittedAt"`
}

// AIDefectInspectionPublic contains public data (shared across orgs)
type AIDefectInspectionPublic struct {
	PartNumber         string  `json:"partNumber"`
	SerialNumber       string  `json:"serialNumber"`
	MaterialType       string  `json:"materialType"`
	InspectionDate     string  `json:"inspectionDate"`
	InspectionType     string  `json:"inspectionType"`
	Organization       string  `json:"organization"`
	RawVideoHash       string  `json:"rawVideoHash"`
	RawVideoIPFS       string  `json:"rawVideoIPFS"`
	RawVideoSize       int64   `json:"rawVideoSize"`
	ProcessedImageHash string  `json:"processedImageHash"`
	ProcessedImageIPFS string  `json:"processedImageIPFS"`
	ROI_Y1             int     `json:"roi_y1"`
	ROI_Y2             int     `json:"roi_y2"`
	ROI_X1             int     `json:"roi_x1"`
	ROI_X2             int     `json:"roi_x2"`
	PulseTime          int     `json:"pulseTime"`
	PCAComponents      int     `json:"pcaComponents"`
	SequenceLength     int     `json:"sequenceLength"`
	ModelName          string  `json:"modelName"`
	ModelVersion       string  `json:"modelVersion"`
	ModelHash          string  `json:"modelHash"`
	DefectDetected     bool    `json:"defectDetected"`
	DefectType         string  `json:"defectType"`
	ConfidenceScore    float64 `json:"confidenceScore"`
	BBox_X1            float64 `json:"bbox_x1"`
	BBox_Y1            float64 `json:"bbox_y1"`
	BBox_X2            float64 `json:"bbox_x2"`
	BBox_Y2            float64 `json:"bbox_y2"`
	IoU                float64 `json:"iou"`
	CenterDistance     float64 `json:"centerDistance"`
	NormCenterDistance float64 `json:"normCenterDistance"`
	HasGroundTruth     bool    `json:"hasGroundTruth"`
	GT_BBox_X1         float64 `json:"gt_bbox_x1"`
	GT_BBox_Y1         float64 `json:"gt_bbox_y1"`
	GT_BBox_X2         float64 `json:"gt_bbox_x2"`
	GT_BBox_Y2         float64 `json:"gt_bbox_y2"`
	TxID               string  `json:"txID"`
	BlockchainTimestamp string `json:"blockchainTimestamp"`
	SubmittedAt        string  `json:"submittedAt"`
}

// AIDefectInspectionPrivate contains private data (inspector name only)
type AIDefectInspectionPrivate struct {
	Inspector string `json:"inspector"`
}

// InitLedger initializes the ledger with sample data
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("AI Defect Inspection Smart Contract Initialized")
	return nil
}

// AddDefectInspection adds a new AI defect inspection to the ledger
func (s *SmartContract) AddDefectInspection(ctx contractapi.TransactionContextInterface,
	inspectionJSON string) error {

	// Parse the input JSON
	var inspection AIDefectInspection
	err := json.Unmarshal([]byte(inspectionJSON), &inspection)
	if err != nil {
		return fmt.Errorf("failed to parse inspection JSON: %v", err)
	}

	// Get transaction metadata
	txID := ctx.GetStub().GetTxID()
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	blockchainTimestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format(time.RFC3339)
	inspection.TxID = txID
	inspection.BlockchainTimestamp = blockchainTimestamp
	inspection.SubmittedAt = time.Now().Format(time.RFC3339)

	// Get the organization MSP ID
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	inspection.Organization = mspID

	// Determine which private collection to use based on org
	var privateCollectionName string
	if mspID == "ManufacturerMSP" {
		privateCollectionName = "aiDefectPrivateManufacturerCollection"
	} else if mspID == "MROLabMSP" {
		privateCollectionName = "aiDefectPrivateMROLabCollection"
	} else {
		return fmt.Errorf("unknown MSP ID: %s", mspID)
	}

	// Split data into public and private
	publicData := AIDefectInspectionPublic{
		PartNumber:          inspection.PartNumber,
		SerialNumber:        inspection.SerialNumber,
		MaterialType:        inspection.MaterialType,
		InspectionDate:      inspection.InspectionDate,
		InspectionType:      inspection.InspectionType,
		Organization:        inspection.Organization,
		RawVideoHash:        inspection.RawVideoHash,
		RawVideoIPFS:        inspection.RawVideoIPFS,
		RawVideoSize:        inspection.RawVideoSize,
		ProcessedImageHash:  inspection.ProcessedImageHash,
		ProcessedImageIPFS:  inspection.ProcessedImageIPFS,
		ROI_Y1:              inspection.ROI_Y1,
		ROI_Y2:              inspection.ROI_Y2,
		ROI_X1:              inspection.ROI_X1,
		ROI_X2:              inspection.ROI_X2,
		PulseTime:           inspection.PulseTime,
		PCAComponents:       inspection.PCAComponents,
		SequenceLength:      inspection.SequenceLength,
		ModelName:           inspection.ModelName,
		ModelVersion:        inspection.ModelVersion,
		ModelHash:           inspection.ModelHash,
		DefectDetected:      inspection.DefectDetected,
		DefectType:          inspection.DefectType,
		ConfidenceScore:     inspection.ConfidenceScore,
		BBox_X1:             inspection.BBox_X1,
		BBox_Y1:             inspection.BBox_Y1,
		BBox_X2:             inspection.BBox_X2,
		BBox_Y2:             inspection.BBox_Y2,
		IoU:                 inspection.IoU,
		CenterDistance:      inspection.CenterDistance,
		NormCenterDistance:  inspection.NormCenterDistance,
		HasGroundTruth:      inspection.HasGroundTruth,
		GT_BBox_X1:          inspection.GT_BBox_X1,
		GT_BBox_Y1:          inspection.GT_BBox_Y1,
		GT_BBox_X2:          inspection.GT_BBox_X2,
		GT_BBox_Y2:          inspection.GT_BBox_Y2,
		TxID:                inspection.TxID,
		BlockchainTimestamp: inspection.BlockchainTimestamp,
		SubmittedAt:         inspection.SubmittedAt,
	}

	privateData := AIDefectInspectionPrivate{
		Inspector: inspection.Inspector,
	}

	// Store public data in public collection
	publicDataJSON, err := json.Marshal(publicData)
	if err != nil {
		return fmt.Errorf("failed to marshal public data: %v", err)
	}

	err = ctx.GetStub().PutState(inspection.SerialNumber, publicDataJSON)
	if err != nil {
		return fmt.Errorf("failed to put public data: %v", err)
	}

	// Store private data in org-specific collection
	privateDataJSON, err := json.Marshal(privateData)
	if err != nil {
		return fmt.Errorf("failed to marshal private data: %v", err)
	}

	err = ctx.GetStub().PutPrivateData(privateCollectionName, inspection.SerialNumber, privateDataJSON)
	if err != nil {
		return fmt.Errorf("failed to put private data: %v", err)
	}

	fmt.Printf("AI Defect Inspection added: %s by %s\n", inspection.SerialNumber, mspID)
	return nil
}

// GetDefectInspection retrieves an AI defect inspection by serial number
func (s *SmartContract) GetDefectInspection(ctx contractapi.TransactionContextInterface,
	serialNumber string) (*AIDefectInspection, error) {

	// Get public data
	publicDataJSON, err := ctx.GetStub().GetState(serialNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to read public data: %v", err)
	}
	if publicDataJSON == nil {
		return nil, fmt.Errorf("inspection %s does not exist", serialNumber)
	}

	var publicData AIDefectInspectionPublic
	err = json.Unmarshal(publicDataJSON, &publicData)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal public data: %v", err)
	}

	// Get MSP ID to determine which private collection to read
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get MSP ID: %v", err)
	}

	var privateCollectionName string
	if mspID == "ManufacturerMSP" {
		privateCollectionName = "aiDefectPrivateManufacturerCollection"
	} else if mspID == "MROLabMSP" {
		privateCollectionName = "aiDefectPrivateMROLabCollection"
	} else {
		return nil, fmt.Errorf("unknown MSP ID: %s", mspID)
	}

	// Try to get private data
	privateDataJSON, err := ctx.GetStub().GetPrivateData(privateCollectionName, serialNumber)
	var inspector string
	if err == nil && privateDataJSON != nil {
		var privateData AIDefectInspectionPrivate
		err = json.Unmarshal(privateDataJSON, &privateData)
		if err == nil {
			inspector = privateData.Inspector
		}
	}

	// Combine public and private data
	inspection := &AIDefectInspection{
		PartNumber:          publicData.PartNumber,
		SerialNumber:        publicData.SerialNumber,
		MaterialType:        publicData.MaterialType,
		InspectionDate:      publicData.InspectionDate,
		InspectionType:      publicData.InspectionType,
		Inspector:           inspector,
		Organization:        publicData.Organization,
		RawVideoHash:        publicData.RawVideoHash,
		RawVideoIPFS:        publicData.RawVideoIPFS,
		RawVideoSize:        publicData.RawVideoSize,
		ProcessedImageHash:  publicData.ProcessedImageHash,
		ProcessedImageIPFS:  publicData.ProcessedImageIPFS,
		ROI_Y1:              publicData.ROI_Y1,
		ROI_Y2:              publicData.ROI_Y2,
		ROI_X1:              publicData.ROI_X1,
		ROI_X2:              publicData.ROI_X2,
		PulseTime:           publicData.PulseTime,
		PCAComponents:       publicData.PCAComponents,
		SequenceLength:      publicData.SequenceLength,
		ModelName:           publicData.ModelName,
		ModelVersion:        publicData.ModelVersion,
		ModelHash:           publicData.ModelHash,
		DefectDetected:      publicData.DefectDetected,
		DefectType:          publicData.DefectType,
		ConfidenceScore:     publicData.ConfidenceScore,
		BBox_X1:             publicData.BBox_X1,
		BBox_Y1:             publicData.BBox_Y1,
		BBox_X2:             publicData.BBox_X2,
		BBox_Y2:             publicData.BBox_Y2,
		IoU:                 publicData.IoU,
		CenterDistance:      publicData.CenterDistance,
		NormCenterDistance:  publicData.NormCenterDistance,
		HasGroundTruth:      publicData.HasGroundTruth,
		GT_BBox_X1:          publicData.GT_BBox_X1,
		GT_BBox_Y1:          publicData.GT_BBox_Y1,
		GT_BBox_X2:          publicData.GT_BBox_X2,
		GT_BBox_Y2:          publicData.GT_BBox_Y2,
		TxID:                publicData.TxID,
		BlockchainTimestamp: publicData.BlockchainTimestamp,
		SubmittedAt:         publicData.SubmittedAt,
	}

	return inspection, nil
}

// GetAllDefectInspections returns all AI defect inspections
func (s *SmartContract) GetAllDefectInspections(ctx contractapi.TransactionContextInterface) ([]*AIDefectInspection, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %v", err)
	}
	defer resultsIterator.Close()

	var inspections []*AIDefectInspection
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %v", err)
		}

		var publicData AIDefectInspectionPublic
		err = json.Unmarshal(queryResponse.Value, &publicData)
		if err != nil {
			continue
		}

		// Get private data if available
		mspID, _ := ctx.GetClientIdentity().GetMSPID()
		var privateCollectionName string
		if mspID == "ManufacturerMSP" {
			privateCollectionName = "aiDefectPrivateManufacturerCollection"
		} else if mspID == "MROLabMSP" {
			privateCollectionName = "aiDefectPrivateMROLabCollection"
		}

		var inspector string
		if privateCollectionName != "" {
			privateDataJSON, err := ctx.GetStub().GetPrivateData(privateCollectionName, publicData.SerialNumber)
			if err == nil && privateDataJSON != nil {
				var privateData AIDefectInspectionPrivate
				err = json.Unmarshal(privateDataJSON, &privateData)
				if err == nil {
					inspector = privateData.Inspector
				}
			}
		}

		inspection := &AIDefectInspection{
			PartNumber:          publicData.PartNumber,
			SerialNumber:        publicData.SerialNumber,
			MaterialType:        publicData.MaterialType,
			InspectionDate:      publicData.InspectionDate,
			InspectionType:      publicData.InspectionType,
			Inspector:           inspector,
			Organization:        publicData.Organization,
			RawVideoHash:        publicData.RawVideoHash,
			RawVideoIPFS:        publicData.RawVideoIPFS,
			RawVideoSize:        publicData.RawVideoSize,
			ProcessedImageHash:  publicData.ProcessedImageHash,
			ProcessedImageIPFS:  publicData.ProcessedImageIPFS,
			ROI_Y1:              publicData.ROI_Y1,
			ROI_Y2:              publicData.ROI_Y2,
			ROI_X1:              publicData.ROI_X1,
			ROI_X2:              publicData.ROI_X2,
			PulseTime:           publicData.PulseTime,
			PCAComponents:       publicData.PCAComponents,
			SequenceLength:      publicData.SequenceLength,
			ModelName:           publicData.ModelName,
			ModelVersion:        publicData.ModelVersion,
			ModelHash:           publicData.ModelHash,
			DefectDetected:      publicData.DefectDetected,
			DefectType:          publicData.DefectType,
			ConfidenceScore:     publicData.ConfidenceScore,
			BBox_X1:             publicData.BBox_X1,
			BBox_Y1:             publicData.BBox_Y1,
			BBox_X2:             publicData.BBox_X2,
			BBox_Y2:             publicData.BBox_Y2,
			IoU:                 publicData.IoU,
			CenterDistance:      publicData.CenterDistance,
			NormCenterDistance:  publicData.NormCenterDistance,
			HasGroundTruth:      publicData.HasGroundTruth,
			GT_BBox_X1:          publicData.GT_BBox_X1,
			GT_BBox_Y1:          publicData.GT_BBox_Y1,
			GT_BBox_X2:          publicData.GT_BBox_X2,
			GT_BBox_Y2:          publicData.GT_BBox_Y2,
			TxID:                publicData.TxID,
			BlockchainTimestamp: publicData.BlockchainTimestamp,
			SubmittedAt:         publicData.SubmittedAt,
		}

		inspections = append(inspections, inspection)
	}

	return inspections, nil
}

// QueryDefectsByConfidence returns inspections above a confidence threshold
func (s *SmartContract) QueryDefectsByConfidence(ctx contractapi.TransactionContextInterface,
	minConfidence float64) ([]*AIDefectInspection, error) {

	allInspections, err := s.GetAllDefectInspections(ctx)
	if err != nil {
		return nil, err
	}

	var filtered []*AIDefectInspection
	for _, inspection := range allInspections {
		if inspection.DefectDetected && inspection.ConfidenceScore >= minConfidence {
			filtered = append(filtered, inspection)
		}
	}

	return filtered, nil
}

// VerifyVideoHash verifies the integrity of the raw video file
func (s *SmartContract) VerifyVideoHash(ctx contractapi.TransactionContextInterface,
	serialNumber string, providedHash string) (bool, error) {

	inspection, err := s.GetDefectInspection(ctx, serialNumber)
	if err != nil {
		return false, err
	}

	return inspection.RawVideoHash == providedHash, nil
}

// GetInspectionsByPart returns all inspections for a given part number
func (s *SmartContract) GetInspectionsByPart(ctx contractapi.TransactionContextInterface,
	partNumber string) ([]*AIDefectInspection, error) {

	allInspections, err := s.GetAllDefectInspections(ctx)
	if err != nil {
		return nil, err
	}

	var filtered []*AIDefectInspection
	for _, inspection := range allInspections {
		if inspection.PartNumber == partNumber {
			filtered = append(filtered, inspection)
		}
	}

	return filtered, nil
}

// CalculateHash is a utility function to calculate SHA-256 hash
func CalculateHash(data []byte) string {
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash)
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating AI defect inspection chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting AI defect inspection chaincode: %v\n", err)
	}
}
