/**
 *    SPDX-License-Identifier: Apache-2.0
 */

import React, { Component } from 'react';
import { withStyles } from '@material-ui/core/styles';
import FontAwesome from 'react-fontawesome';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import { Table, Card, CardBody, CardTitle } from 'reactstrap';
import JSONTree from 'react-json-tree';
import { transactionType } from '../types';
import Modal from '../Styled/Modal';
/* eslint-disable */
const readTheme = {
	base00: '#f3f3f3',
	base01: '#2e2f30',
	base02: '#515253',
	base03: '#737475',
	base04: '#959697',
	base05: '#b7b8b9',
	base06: '#dadbdc',
	base07: '#fcfdfe',
	base08: '#e31a1c',
	base09: '#e6550d',
	base0A: '#dca060',
	base0B: '#31a354',
	base0C: '#80b1d3',
	base0D: '#3182bd',
	base0E: '#756bb1',
	base0F: '#b15928'
};
const writeTheme = {
	base00: '#ffffff',
	base01: '#2e2f30',
	base02: '#515253',
	base03: '#737475',
	base04: '#959697',
	base05: '#b7b8b9',
	base06: '#dadbdc',
	base07: '#fcfdfe',
	base08: '#e31a1c',
	base09: '#e6550d',
	base0A: '#dca060',
	base0B: '#31a354',
	base0C: '#80b1d3',
	base0D: '#3182bd',
	base0E: '#756bb1',
	base0F: '#b15928'
};
/* eslint-enable */
const styles = theme => ({
	listIcon: {
		color: '#ffffff',
		marginRight: 20
	},
	JSONtree: {
		'& ul': {
			backgroundColor: 'transparent !important',
			color: '#fff'
		}
	},
	readset_null: {
		display: 'none'
	}
});

const reads = {
	color: '#2AA233'
};
const writes = {
	color: '#DD8016'
};

export class TransactionView extends Component {
	handleClose = () => {
		const { onClose } = this.props;
		onClose();
	};

	decodeProposalInput = (hexInput) => {
		if (!hexInput) {
			return null;
		}

		try {
			// Split by comma (multiple arguments are comma-separated in the DB)
			const hexArgs = hexInput.split(',');
			const decodedArgs = [];

			for (let i = 0; i < hexArgs.length; i++) {
				const hexArg = hexArgs[i].trim();

				// Convert hex to string
				let decoded = '';
				for (let j = 0; j < hexArg.length; j += 2) {
					decoded += String.fromCharCode(parseInt(hexArg.substr(j, 2), 16));
				}

				try {
					// Try to parse as JSON (it might be a Buffer object)
					const parsed = JSON.parse(decoded);

					// Check if it's a Buffer object with data array
					if (parsed.type === 'Buffer' && Array.isArray(parsed.data)) {
						// Convert Buffer data array to string
						let bufferStr = '';
						for (const byte of parsed.data) {
							bufferStr += String.fromCharCode(byte);
						}

						// Try to parse the buffer string as JSON
						try {
							decodedArgs.push(JSON.parse(bufferStr));
						} catch (e) {
							decodedArgs.push(bufferStr);
						}
					} else {
						decodedArgs.push(parsed);
					}
				} catch (e) {
					// Not JSON, just add the decoded string
					decodedArgs.push(decoded);
				}
			}

			return {
				function: decodedArgs[0] || 'Unknown',
				arguments: decodedArgs.slice(1)
			};
		} catch (error) {
			return { error: 'Failed to decode input: ' + error.message };
		}
	};

	render() {
		const { transaction, classes } = this.props;
		if (transaction) {
			let baseUrl =
				window.location.protocol +
				'//' +
				window.location.hostname +
				':' +
				window.location.port;
			let directLink =
				baseUrl + '/?tab=transactions&transId=' + transaction.txhash;
			return (
				<Modal>
					{modalClasses => (
						<div className={modalClasses.dialog}>
							<Card className={modalClasses.card}>
								<CardTitle className={modalClasses.title}>
									<FontAwesome name="list-alt" className={classes.listIcon} />
									Transaction Details
									<button
										type="button"
										onClick={this.handleClose}
										className={modalClasses.closeBtn}
									>
										<FontAwesome name="close" />
									</button>
								</CardTitle>
								<CardBody className={modalClasses.body}>
									<Table striped hover responsive className="table-striped">
										<tbody>
											<tr>
												<th>Transaction ID:</th>
												<td>
													{transaction.txhash}
													<button type="button" className={modalClasses.copyBtn}>
														<div className={modalClasses.copy}>Copy</div>
														<div className={modalClasses.copied}>Copied</div>
														<CopyToClipboard text={transaction.txhash}>
															<FontAwesome name="copy" />
														</CopyToClipboard>
													</button>
												</td>
											</tr>
											<tr>
												<th>Validation Code:</th>
												<td>{transaction.validation_code}</td>
											</tr>
											<tr>
												<th>Payload Proposal Hash:</th>
												<td>{transaction.payload_proposal_hash}</td>
											</tr>
											<tr>
												<th>Creator MSP:</th>
												<td>{transaction.creator_msp_id}</td>
											</tr>
											<tr>
												<th>Endorser:</th>
												<td>{transaction.endorser_msp_id}</td>
											</tr>
											<tr>
												<th>Chaincode Name:</th>
												<td>{transaction.chaincodename}</td>
											</tr>
											<tr>
												<th>Type:</th>
												<td>{transaction.type}</td>
											</tr>
											<tr>
												<th>Time:</th>
												<td>{transaction.createdt}</td>
											</tr>
											<tr>
												<th>Direct Link:</th>
												<td>
													{directLink}
													<button type="button" className={modalClasses.copyBtn}>
														<div className={modalClasses.copy}>Copy</div>
														<div className={modalClasses.copied}>Copied</div>
														<CopyToClipboard text={directLink}>
															<FontAwesome name="copy" />
														</CopyToClipboard>
													</button>
												</td>
											</tr>
											<tr className={!transaction.read_set && classes.readset_null}>
												<th style={reads}>Reads:</th>
												<td className={classes.JSONtree}>
													<JSONTree
														data={transaction.read_set}
														theme={readTheme}
														invertTheme={false}
													/>
												</td>
											</tr>
											<tr className={!transaction.read_set && classes.readset_null}>
												<th style={writes}>Writes:</th>
												<td className={classes.JSONtree}>
													<JSONTree
														data={transaction.write_set}
														theme={writeTheme}
														invertTheme={false}
													/>
												</td>
											</tr>
											<tr className={!transaction.chaincode_proposal_input && classes.readset_null}>
												<th style={reads}>Chaincode Input:</th>
												<td className={classes.JSONtree}>
													<JSONTree
														data={this.decodeProposalInput(transaction.chaincode_proposal_input)}
														theme={readTheme}
														invertTheme={false}
													/>
												</td>
											</tr>
										</tbody>
									</Table>
								</CardBody>
							</Card>
						</div>
					)}
				</Modal>
			);
		}
		return (
			<Modal>
				{modalClasses => (
					<div>
						<CardTitle className={modalClasses.title}>
							<FontAwesome name="list-alt" className={classes.listIcon} />
							Transaction Details
							<button
								type="button"
								onClick={this.handleClose}
								className={modalClasses.closeBtn}
							>
								<FontAwesome name="close" />
							</button>
						</CardTitle>
						<div align="center">
							<CardBody className={modalClasses.body}>
								<span>
									{' '}
									<FontAwesome name="circle-o-notch" size="3x" spin />
								</span>
							</CardBody>
						</div>
					</div>
				)}
			</Modal>
		);
	}
}

TransactionView.propTypes = {
	transaction: transactionType
};

TransactionView.defaultProps = {
	transaction: null
};

export default withStyles(styles)(TransactionView);
